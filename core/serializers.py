from rest_framework import serializers
from .models import User, Product, DigitalService, Order, OrderItem, Shop, MarketingRequest, InfluencerAd, Notification, AdPurchase
from django.contrib.auth.hashers import make_password

# 1. Registration serializer for the mobile app.
class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    full_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    email = serializers.EmailField(required=False, allow_blank=True, default='')
    
    class Meta:
        model = User
        fields = [
            'username',
            'email',
            'password',
            'role',
            'full_name',
            'first_name',
            'last_name',
            'phone',
            'address',
            'latitude',
            'longitude',
            'profile_image',
            'vehicle_type',
            'vehicle_plate',
            'vehicle_image',
            'bank_account',
            'national_id',
            'driving_license',
            'resume',
            'social_links',
            'specialty',
        ]
    
    def create(self, validated_data):
        """Create a new user and hash the password."""
        full_name = (validated_data.pop('full_name', '') or '').strip()
        if full_name and not validated_data.get('first_name') and not validated_data.get('last_name'):
            parts = full_name.split()
            validated_data['first_name'] = parts[0]
            if len(parts) > 1:
                validated_data['last_name'] = ' '.join(parts[1:])
        validated_data['password'] = make_password(validated_data['password'])
        user = User.objects.create(**validated_data)
        return user

# 2. User serializer.
class UserSerializer(serializers.ModelSerializer):
    store_name = serializers.SerializerMethodField()
    store_description = serializers.SerializerMethodField()
    store_type = serializers.SerializerMethodField()
    store_logo = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'first_name',
            'last_name',
            'email',
            'role',
            'phone',
            'address',
            'latitude',
            'longitude',
            'wallet_balance',
            'profile_image',
            'vehicle_type',
            'vehicle_plate',
            'vehicle_image',
            'bank_account',
            'national_id',
            'driving_license',
            'store_name',
            'store_description',
            'store_type',
            'store_logo',
            'resume',
            'social_links',
            'specialty',
            'is_approved',
        ]
        read_only_fields = ['id', 'role', 'wallet_balance', 'is_approved']

    def get_store_name(self, obj):
        return getattr(getattr(obj, 'shop', None), 'name', None)

    def get_store_description(self, obj):
        return getattr(getattr(obj, 'shop', None), 'description', None)

    def get_store_type(self, obj):
        return getattr(getattr(obj, 'shop', None), 'category', None)

    def get_store_logo(self, obj):
        shop = getattr(obj, 'shop', None)
        return shop.image.name if shop and shop.image else None

    def update(self, instance, validated_data):
        user = super().update(instance, validated_data)
        raw_data = getattr(self, 'initial_data', {}) or {}
        if user.role == 'vendor':
            shop_fields = {}
            if 'store_name' in raw_data:
                shop_fields['name'] = (raw_data.get('store_name') or '').strip()
            if 'store_description' in raw_data:
                shop_fields['description'] = (raw_data.get('store_description') or '').strip()
            if 'store_type' in raw_data:
                shop_fields['category'] = (raw_data.get('store_type') or '').strip()
            if raw_data.get('store_logo'):
                shop_fields['image'] = raw_data.get('store_logo')
            if shop_fields:
                shop_fields.setdefault('name', getattr(getattr(user, 'shop', None), 'name', '') or user.username)
                Shop.objects.update_or_create(vendor=user, defaults=shop_fields)
        return user


class DriverInfoSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'full_name',
            'email',
            'phone',
            'profile_image',
            'vehicle_type',
            'vehicle_plate',
            'vehicle_image',
        ]

    def get_full_name(self, obj):
        full_name = obj.get_full_name().strip()
        return full_name or obj.username

# 2. Product serializer for physical items.
class ProductSerializer(serializers.ModelSerializer):
    vendor_name = serializers.ReadOnlyField(source='vendor.username')
    
    class Meta:
        model = Product
        fields = '__all__'

class ShopSerializer(serializers.ModelSerializer):
    vendor_name = serializers.ReadOnlyField(source='vendor.username')

    class Meta:
        model = Shop
        fields = ['id', 'vendor', 'vendor_name', 'name', 'description', 'category', 'image', 'is_active', 'created_at']

    def validate_vendor(self, value):
        request = self.context.get('request')
        if request and request.user.role == 'vendor' and value != request.user:
            raise serializers.ValidationError('Impossible de choisir un autre vendeur.')
        return value

# 3. Digital service serializer with content protection.
class DigitalServiceSerializer(serializers.ModelSerializer):
    vendor_name = serializers.ReadOnlyField(source='vendor.username')
    student_count = serializers.SerializerMethodField()

    class Meta:
        model = DigitalService
        fields = [
            'id', 'type', 'title', 'description', 'price', 
            'required_field_name', 'content_link', 'vendor_name', 'image', 'student_count'
        ]

    def get_student_count(self, obj):
        return OrderItem.objects.filter(
            digital_service=obj,
            order__status__in=['paid', 'delivered']
        ).values('order__customer').distinct().count()

    def to_representation(self, instance):
        """Protect content links until the customer has paid for the service."""
        representation = super().to_representation(instance)
        request = self.context.get('request')
        
        # Admins can always see the content link.
        if request and request.user.is_authenticated and (request.user.is_staff or getattr(request.user, 'role', '') == 'admin'):
            return representation

        # Customers can see the link only after a paid or delivered order.
        if request and request.user.is_authenticated:
            has_paid = OrderItem.objects.filter(
                order__customer=request.user,
                order__status__in=['paid', 'delivered'],
                digital_service=instance
            ).exists()

            if not has_paid:
                representation['content_link'] = "Lien protégé - Disponible après paiement"
        else:
            representation['content_link'] = "Connectez-vous pour accéder au contenu"
            
        return representation

# 4. Order item serializer.
class OrderItemSerializer(serializers.ModelSerializer):
    item_name = serializers.SerializerMethodField()
    item_description = serializers.SerializerMethodField()
    item_type = serializers.SerializerMethodField()
    order_id = serializers.ReadOnlyField(source='order.id')
    order_status = serializers.ReadOnlyField(source='order.status')
    customer_name = serializers.ReadOnlyField(source='order.customer.username')
    total_amount = serializers.ReadOnlyField(source='order.total_amount')
    created_at = serializers.DateTimeField(source='order.created_at', read_only=True)
    vendor_id = serializers.SerializerMethodField()
    content_link = serializers.ReadOnlyField(source='digital_service.content_link')
    digital_service_id = serializers.ReadOnlyField(source='digital_service.id')
    product_id = serializers.ReadOnlyField(source='product.id')

    class Meta:
        model = OrderItem
        fields = [
            'id', 'order_id', 'order_status', 'item_name', 'item_description', 'item_type', 'quantity',
            'customer_name', 'total_amount',
            'vendor_share', 'influencer_share', 'platform_share', 'driver_share',
            'vendor_ready', 'vendor_id',
            'created_at', 'content_link', 'topup_account_id', 'topup_payer', 'topup_recharge_type',
            'digital_service_id', 'product_id',
        ]

    def get_vendor_id(self, obj):
        if obj.product:
            return obj.product.vendor_id
        return None

    def get_item_name(self, obj):
        if obj.product:
            return obj.product.name
        if obj.digital_service:
            return obj.digital_service.title
        return "Inconnu"

    def get_item_description(self, obj):
        if obj.product:
            return obj.product.description
        if obj.digital_service:
            return obj.digital_service.description
        return ""

    def get_item_type(self, obj):
        if obj.digital_service:
            return obj.digital_service.type
        if obj.product:
            return 'product'
        return None

# 5. Order serializer.
class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    customer_name = serializers.ReadOnlyField(source='customer.username')
    driver_name = serializers.ReadOnlyField(source='driver.username', allow_null=True)
    vendors_ready = serializers.SerializerMethodField()
    vendor_locations = serializers.SerializerMethodField()
    influencer_earnings = serializers.SerializerMethodField()
    driver_info = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'customer_name', 'driver', 'driver_name',
            'total_amount', 'status', 'created_at', 'items',
            'driver_rating', 'is_shares_distributed', 'is_disbursed',
            'vendor_latitude', 'vendor_longitude',
            'customer_latitude', 'customer_longitude',
            'delivery_address', 'vendors_ready', 'vendor_locations',
            'influencer_earnings', 'driver_info',
        ]
        read_only_fields = ['customer_name', 'driver_name', 'total_amount']

    def get_vendors_ready(self, obj):
        """Returns dict with ready/total vendor count for multi-vendor orders."""
        physical_items = [i for i in obj.items.all() if i.product]
        if not physical_items:
            return {'ready': 0, 'total': 0, 'all_ready': True}
        vendors = {}
        for item in physical_items:
            vid = item.product.vendor_id
            if vid not in vendors:
                vendors[vid] = False
            if item.vendor_ready:
                vendors[vid] = True
        total = len(vendors)
        ready = sum(1 for v in vendors.values() if v)
        return {'ready': ready, 'total': total, 'all_ready': ready == total}

    def get_influencer_earnings(self, obj):
        """Sum of influencer_share across all items in this order."""
        return float(sum(
            item.influencer_share for item in obj.items.all()
            if item.influencer_share
        ))

    def get_driver_info(self, obj):
        if not obj.driver:
            return None
        return DriverInfoSerializer(obj.driver, context=self.context).data

    def get_vendor_locations(self, obj):
        """Returns list of vendor locations for multi-vendor route display.
        Vendors without GPS get deterministic fallback coords around Nouakchott."""
        # Nouakchott center as fallback anchor
        BASE_LAT, BASE_LNG = 18.080, -15.970
        physical_items = [i for i in obj.items.all() if i.product]
        seen = {}
        for item in physical_items:
            vid = item.product.vendor_id
            if vid not in seen:
                vendor = item.product.vendor
                lat = float(vendor.latitude) if vendor.latitude else None
                lng = float(vendor.longitude) if vendor.longitude else None
                # Deterministic offset when GPS is missing (spread vendors ~300m apart)
                if lat is None or lng is None:
                    import math
                    angle = (vid * 137.5) * (math.pi / 180)  # golden angle
                    radius = 0.003 * ((vid % 5) + 1)  # ~300m steps
                    lat = BASE_LAT + radius * math.cos(angle)
                    lng = BASE_LNG + radius * math.sin(angle)
                seen[vid] = {
                    'vendor_id': vid,
                    'name': vendor.username,
                    'lat': lat,
                    'lng': lng,
                }
        return list(seen.values())


class OrderItemInputSerializer(serializers.Serializer):
    product = serializers.IntegerField(required=False, allow_null=True)
    digital_service = serializers.IntegerField(required=False, allow_null=True)
    quantity = serializers.IntegerField(min_value=1, default=1)
    influencer = serializers.IntegerField(required=False, allow_null=True)
    topup_account_id = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    topup_payer = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    topup_recharge_type = serializers.CharField(required=False, allow_blank=True, allow_null=True)


class CreateOrderSerializer(serializers.Serializer):
    items = OrderItemInputSerializer(many=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError('Veuillez ajouter au moins un article.')
        return value


class ProductCreateSerializer(serializers.ModelSerializer):
    image = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = Product
        fields = ['name', 'description', 'price', 'stock_quantity', 'color', 'size', 'image', 'is_approved']


class MarketingRequestSerializer(serializers.ModelSerializer):
    influencer_name = serializers.ReadOnlyField(source='influencer.username')
    vendor_name = serializers.ReadOnlyField(source='vendor.username')
    product_name = serializers.ReadOnlyField(source='product.name')
    product_image = serializers.SerializerMethodField()

    class Meta:
        model = MarketingRequest
        fields = ['id', 'influencer', 'influencer_name', 'vendor', 'vendor_name', 'product', 'product_name', 'product_image', 'status', 'created_at']
        read_only_fields = ['status', 'created_at', 'influencer', 'vendor']

    def get_product_image(self, obj):
        if obj.product and obj.product.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.product.image.url)
            return obj.product.image.url
        return None


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'type', 'title', 'body', 'data', 'is_read', 'created_at']
        read_only_fields = ['id', 'type', 'title', 'body', 'data', 'created_at']


class AdPurchaseSerializer(serializers.ModelSerializer):
    buyer_name = serializers.ReadOnlyField(source='buyer.get_full_name')
    buyer_phone = serializers.ReadOnlyField(source='buyer.phone')

    class Meta:
        model = AdPurchase
        fields = ['id', 'ad', 'buyer_name', 'buyer_phone', 'amount', 'created_at']
        read_only_fields = ['id', 'buyer_name', 'buyer_phone', 'amount', 'created_at']


class InfluencerAdSerializer(serializers.ModelSerializer):
    influencer_id = serializers.ReadOnlyField(source='influencer.id')
    influencer_name = serializers.ReadOnlyField(source='influencer.username')
    influencer_phone = serializers.ReadOnlyField(source='influencer.phone')
    price_mru = serializers.IntegerField(source='price', read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = InfluencerAd
        fields = [
            'id',
            'influencer',
            'influencer_id',
            'influencer_name',
            'influencer_phone',
            'description',
            'price',
            'price_mru',
            'image',
            'image_url',
            'is_active',
            'created_at',
        ]
        read_only_fields = [
            'influencer',
            'influencer_id',
            'influencer_name',
            'influencer_phone',
            'price_mru',
            'image_url',
            'created_at',
        ]

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return ''
