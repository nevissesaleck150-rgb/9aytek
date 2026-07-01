from decimal import Decimal
import re
from django.db import transaction
from django.db.models import Sum, Q, F, DecimalField
from django.utils import timezone
from django.contrib.auth import authenticate
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, OrderItem, Order, Product, DigitalService, Shop, distribute_order_shares, MarketingRequest, InfluencerAd, Notification, AdPurchase, WalletTransaction
from .serializers import (
    UserSerializer,
    UserRegistrationSerializer,
    OrderItemSerializer,
    OrderSerializer,
    ProductSerializer,
    ProductCreateSerializer,
    DigitalServiceSerializer,
    ShopSerializer,
    CreateOrderSerializer,
    MarketingRequestSerializer,
    InfluencerAdSerializer,
    NotificationSerializer,
    AdPurchaseSerializer,
)

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]

    def get_permissions(self):
        # Public-ish actions — any authenticated user
        if self.action in ('list', 'retrieve'):
            return [permissions.IsAuthenticated()]
        # Admin actions — staff OR role='admin'
        if self.action in ('approve', 'reject', 'create', 'update', 'partial_update', 'destroy'):
            return [permissions.IsAuthenticated()]
        return super().get_permissions()

    def _require_admin(self, request):
        if not (request.user.is_staff or request.user.role == 'admin'):
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Action réservée aux administrateurs.')

    def retrieve(self, request, *args, **kwargs):
        user = request.user
        if user.role != 'admin' and not user.is_staff:
            return Response({'error': 'Permission refusée.'}, status=status.HTTP_403_FORBIDDEN)
        return super().retrieve(request, *args, **kwargs)

    def list(self, request, *args, **kwargs):
        # Return limited public info for non-admin users
        user = request.user
        if not user.is_staff and user.role != 'admin':
            # Show approved users + all influencers (influencers don't require approval for visibility)
            users = User.objects.filter(
                Q(is_approved=True) | Q(role='influencer')
            ).only('id', 'username', 'first_name', 'last_name', 'role', 'email', 'profile_image')
            payload = []
            for u in users:
                profile_image = ''
                if u.profile_image:
                    profile_image = request.build_absolute_uri(u.profile_image.url)
                payload.append({
                    'id': u.id,
                    'username': u.username,
                    'first_name': u.first_name,
                    'last_name': u.last_name,
                    'role': u.role,
                    'email': u.email,
                    'profile_image': profile_image,
                })
            return Response(payload)
        return super().list(request, *args, **kwargs)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        self._require_admin(request)
        user = self.get_object()
        user.is_approved = True
        user.save()
        return Response({'status': f'Utilisateur {user.username} approuvé'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        self._require_admin(request)
        user = self.get_object()
        if user.is_staff or user.role == 'admin':
            return Response({'error': 'Impossible de refuser ce compte.'}, status=status.HTTP_400_BAD_REQUEST)
        user.is_approved = False
        user.save()
        return Response({'status': f'Utilisateur {user.username} rejeté.'})

    @action(detail=False, methods=['get'])
    def dashboard_stats(self, request):
        total_revenue = Order.objects.aggregate(total=Sum('total_amount'))['total'] or 0
        total_orders = Order.objects.count()
        incomplete_orders = Order.objects.exclude(status='delivered').count()
        active_vendors = User.objects.filter(role='vendor', is_approved=True).count()
        active_influencers = User.objects.filter(role='influencer', is_approved=True).count()
        active_drivers = User.objects.filter(role='driver', is_approved=True).count()
        active_shops = Shop.objects.filter(is_active=True).count()
        pending_approvals = User.objects.filter(is_approved=False).count()
        daily_orders = Order.objects.filter(created_at__date=timezone.now().date()).count()
        daily_topup_orders = Order.objects.filter(
            created_at__date=timezone.now().date(),
            items__digital_service__type='topup'
        ).distinct().count()
        daily_course_orders = Order.objects.filter(
            created_at__date=timezone.now().date(),
            items__digital_service__type='course'
        ).distinct().count()

        revenue_by_shop = list(
            OrderItem.objects.filter(product__vendor__shop__isnull=False)
                .values(
                    shop_name=F('product__vendor__shop__name'),
                    vendor_name=F('product__vendor__username')
                )
                .annotate(revenue=Sum(F('quantity') * F('product__price'), output_field=DecimalField(max_digits=18, decimal_places=2)))
                .order_by('-revenue')[:8]
        )

        revenue_by_category = list(
            OrderItem.objects.filter(product__vendor__shop__category__isnull=False)
                .values(category=F('product__vendor__shop__category'))
                .annotate(revenue=Sum(F('quantity') * F('product__price'), output_field=DecimalField(max_digits=18, decimal_places=2)))
                .order_by('-revenue')
        )

        stats = {
            'total_revenue': total_revenue,
            'total_orders': total_orders,
            'incomplete_orders': incomplete_orders,
            'daily_orders': daily_orders,
            'daily_topup_orders': daily_topup_orders,
            'daily_course_orders': daily_course_orders,
            'active_vendors': active_vendors,
            'active_influencers': active_influencers,
            'active_drivers': active_drivers,
            'active_shops': active_shops,
            'pending_approvals': pending_approvals,
            'revenue_by_shop': revenue_by_shop,
            'revenue_by_category': revenue_by_category,
        }
        return Response(stats)

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    def register(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(
                {
                    'success': True,
                    'message': 'Compte créé avec succès. Votre compte sera activé après approbation de l\'administrateur.',
                    'user': {
                        'id': user.id,
                        'username': user.username,
                        'email': user.email,
                        'role': user.role,
                    }
                },
                status=status.HTTP_201_CREATED
            )
        return Response(
            {'success': False, 'message': 'Veuillez vérifier les informations saisies', 'errors': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )


class DigitalServiceViewSet(viewsets.ModelViewSet):
    queryset = DigitalService.objects.all()
    serializer_class = DigitalServiceSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def topup_requests(self, request):
        requests_qs = OrderItem.objects.filter(
            digital_service__type='topup',
            order__status__in=['paid', 'delivered']
        ).order_by('-order__created_at')
        serializer = OrderItemSerializer(requests_qs, many=True)
        return Response(serializer.data)


class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all().order_by('-created_at')
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Order.objects.all().order_by('-created_at')
        if user.is_staff or getattr(user, 'role', '') == 'admin':
            return qs
        if user.role == 'customer':
            return qs.filter(customer=user)
        if user.role == 'vendor':
            return qs.filter(items__product__vendor=user).distinct()
        if user.role == 'influencer':
            return qs.filter(items__influencer=user).distinct()
        if user.role == 'driver':
            available = qs.filter(driver__isnull=True, status='ready')
            mine = qs.filter(driver=user)
            return (available | mine).distinct()
        return qs.none()

    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)

    @action(detail=False, methods=['post'])
    def create_with_items(self, request):
        serializer = CreateOrderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        items_data = serializer.validated_data['items']

        with transaction.atomic():
            total = Decimal('0.00')
            order_items = []
            for row in items_data:
                product_id = row.get('product')
                digital_service_id = row.get('digital_service')
                influencer_ad_id = row.get('influencer_ad')
                qty = row['quantity']
                influencer_id = row.get('influencer')
                topup_account_id = (row.get('topup_account_id') or '').strip()
                topup_payer = (row.get('topup_payer') or '').strip()
                topup_recharge_type = (row.get('topup_recharge_type') or '').strip()
                
                prod = None
                ds = None
                ad = None
                price = Decimal('0.00')
                
                if product_id:
                    prod = Product.objects.get(pk=product_id)
                    price = Decimal(str(prod.price))
                    # Check stock availability
                    if prod.stock_quantity < qty:
                        return Response(
                            {'error': f"Stock insuffisant pour '{prod.name}'. Disponible: {prod.stock_quantity}"},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                elif digital_service_id:
                    ds = DigitalService.objects.get(pk=digital_service_id)
                    price = Decimal(str(ds.price))
                    if ds.type == 'topup':
                        if not topup_account_id:
                            return Response(
                                {'error': 'L’identifiant du compte est requis pour la recharge.'},
                                status=status.HTTP_400_BAD_REQUEST
                            )
                        if not topup_payer:
                            topup_payer = request.user.get_full_name() or request.user.username
                elif influencer_ad_id:
                    ad = InfluencerAd.objects.select_related('influencer').get(pk=influencer_ad_id)
                    price = Decimal(str(ad.price))
                    influencer_id = ad.influencer_id
                else:
                    return Response(
                        {'error': 'Chaque article doit contenir un produit, un service ou une annonce.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                    
                total += price * qty
                order_items.append((prod, ds, ad, qty, influencer_id, topup_account_id, topup_payer, topup_recharge_type))

            order = Order.objects.create(
                customer=request.user,
                total_amount=total,
                status='pending',
            )
            for prod, ds, ad, qty, influencer_id, topup_account_id, topup_payer, topup_recharge_type in order_items:
                influencer = None
                if influencer_id:
                    influencer = User.objects.filter(pk=influencer_id, role='influencer').first()
                OrderItem.objects.create(
                    order=order,
                    product=prod,
                    digital_service=ds,
                    influencer_ad=ad,
                    quantity=qty,
                    influencer=influencer,
                    topup_account_id=topup_account_id or None,
                    topup_payer=topup_payer or None,
                    topup_recharge_type=topup_recharge_type or None,
                )

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def confirm_bankily(self, request, pk=None):
        order = self.get_object()
        if order.status != 'pending':
            return Response({'error': 'Statut invalide'}, status=status.HTTP_400_BAD_REQUEST)
        order.status = 'paid'
        order.save(update_fields=['status'])
        
        # Decrement stock for physical products
        for item in order.items.select_related('product').all():
            if item.product:
                item.product.stock_quantity = max(0, item.product.stock_quantity - item.quantity)
                item.product.save(update_fields=['stock_quantity'])

        for item in order.items.select_related('influencer_ad').filter(influencer_ad__isnull=False):
            AdPurchase.objects.create(
                ad=item.influencer_ad,
                buyer=order.customer,
                amount=item.influencer_ad.price * item.quantity,
            )
        
        # Digital services: distribute immediately EXCEPT topups (topups wait for admin confirmation).
        is_digital = all(item.digital_service is not None for item in order.items.all())
        has_physical = order.items.filter(product__isnull=False).exists()
        is_topup = any(
            item.digital_service is not None and item.digital_service.type == 'topup'
            for item in order.items.all()
        )
        if not has_physical and not is_topup:
            distribute_order_shares(order)
        else:
            # Physical order paid — notify all active drivers
            drivers = User.objects.filter(role='driver', is_approved=True)
            notifs = [
                Notification(
                    user=driver,
                    type='new_order',
                    title='Nouvelle livraison disponible !',
                    body=f'Commande #{order.id} · {order.total_amount} MRU — soyez le premier à accepter',
                    data={'order_id': order.id, 'amount': str(order.total_amount)},
                )
                for driver in drivers
            ]
            if notifs:
                Notification.objects.bulk_create(notifs)

        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def complete_topup(self, request, pk=None):
        order = self.get_object()
        if order.status != 'paid':
            return Response({'error': 'La commande topup doit être payée.'}, status=status.HTTP_400_BAD_REQUEST)
        if not order.items.filter(digital_service__type='topup').exists():
            return Response({'error': 'Commande non liée à un topup.'}, status=status.HTTP_400_BAD_REQUEST)

        order.status = 'delivered'
        order.save(update_fields=['status'])
        distribute_order_shares(order)
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=['post'])
    def accept_delivery(self, request, pk=None):
        if request.user.role != 'driver':
            return Response({'error': 'Livreur uniquement'}, status=status.HTTP_403_FORBIDDEN)
        order = self.get_object()
        if order.driver and order.driver != request.user:
            return Response({'error': 'Commande déjà assignée à un autre chauffeur'}, status=status.HTTP_409_CONFLICT)
        if order.status != 'ready':
            return Response({'error': 'La commande doit être prête avant acceptation.'}, status=status.HTTP_400_BAD_REQUEST)
        order.driver = request.user
        # Populate vendor/customer locations from User profiles
        if order.customer and order.customer.latitude and order.customer.longitude:
            order.customer_latitude = order.customer.latitude
            order.customer_longitude = order.customer.longitude
        if order.customer:
            order.delivery_address = order.customer.address or ''
        # Get vendor location from the first product's vendor
        for item in order.items.select_related('product__vendor').all():
            if item.product and item.product.vendor:
                vendor = item.product.vendor
                if vendor.latitude and vendor.longitude:
                    order.vendor_latitude = vendor.latitude
                    order.vendor_longitude = vendor.longitude
                break  # use first vendor
        order.save()
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=['post'])
    def release_delivery(self, request, pk=None):
        order = self.get_object()
        if order.driver != request.user and not request.user.is_staff:
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        order.driver = None
        order.save(update_fields=['driver'])
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=['post'])
    def confirm_delivery(self, request, pk=None):
        order = self.get_object()
        if order.status != 'arrived':
            return Response({'error': 'Statut invalide pour confirmation'}, status=status.HTTP_400_BAD_REQUEST)
        
        rating = request.data.get('driver_rating')
        if rating is not None:
            try:
                order.driver_rating = int(rating)
            except ValueError:
                pass

        order.status = 'delivered'
        order.save(update_fields=['status', 'driver_rating'])
        distribute_order_shares(order)

        if order.driver and order.driver_rating is not None:
            stars = '⭐' * order.driver_rating
            Notification.objects.create(
                user=order.driver,
                type='driver_rating',
                title='Nouveau avis client !',
                body=f'Le client {order.customer.get_full_name() or order.customer.username} vous a donné {order.driver_rating}/5 {stars}',
                data={'rating': order.driver_rating, 'order_id': order.id},
            )
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=['post', 'patch'])
    def update_status(self, request, pk=None):
        order = self.get_object()
        new_status = request.data.get('status')
        allowed = dict(Order.STATUS_CHOICES).keys()
        if new_status not in allowed:
            return Response({'error': 'Statut invalide'}, status=status.HTTP_400_BAD_REQUEST)
        user = request.user
        if user.role == 'vendor' and new_status not in ('ready',):
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        if user.role == 'driver' and new_status not in ('on_way', 'arrived'):
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        if user.role == 'customer' and new_status != 'delivered':
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        
        # Vendor "ready" flow: mark vendor's items as ready, then auto-promote if all vendors are ready
        if user.role == 'vendor' and new_status == 'ready':
            # Mark all items belonging to this vendor as ready
            vendor_items = order.items.filter(product__vendor=user)
            if not vendor_items.exists():
                return Response({'error': 'Aucun article trouvé pour ce marchand'}, status=status.HTTP_404_NOT_FOUND)
            vendor_items.update(vendor_ready=True)

            # Check if ALL distinct vendors have marked their items ready
            physical_items = order.items.filter(product__isnull=False).select_related('product')
            vendor_status = {}
            for item in physical_items:
                vid = item.product.vendor_id
                if vid not in vendor_status:
                    vendor_status[vid] = True
                if not item.vendor_ready:
                    vendor_status[vid] = False

            all_ready = all(vendor_status.values()) if vendor_status else True
            if all_ready and order.status == 'paid':
                order.status = 'ready'
                order.save(update_fields=['status'])

            return Response(OrderSerializer(order).data)

        order.status = new_status
        order.save(update_fields=['status'])
        
        if new_status == 'delivered':
            distribute_order_shares(order)
            
        return Response(OrderSerializer(order).data)


class ShopViewSet(viewsets.ModelViewSet):
    queryset = Shop.objects.all().order_by('-created_at')
    serializer_class = ShopSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and (user.is_staff or user.role == 'admin'):
            return Shop.objects.all().order_by('-created_at')
        if user.is_authenticated and user.role == 'vendor':
            return Shop.objects.filter(vendor=user).order_by('-created_at')
        return Shop.objects.filter(is_active=True).order_by('-created_at')

    def perform_create(self, serializer):
        if self.request.user.role == 'vendor':
            serializer.save(vendor=self.request.user)
        else:
            serializer.save()

    def perform_update(self, serializer):
        if self.request.user.role == 'vendor':
            serializer.save(vendor=self.request.user)
        else:
            serializer.save()


class FinanceViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = OrderItem.objects.all().order_by('-order__created_at')
    serializer_class = OrderItemSerializer
    permission_classes = [permissions.IsAdminUser]


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all().order_by('-created_at')
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and user.role == 'vendor':
            return Product.objects.filter(vendor=user).order_by('-created_at')
        if user.is_authenticated and (user.is_staff or user.role == 'admin'):
            return Product.objects.all().order_by('-created_at')
        # Customers and anonymous users: only approved products from active shops with stock
        return Product.objects.filter(
            is_approved=True,
            vendor__shop__is_active=True,
            stock_quantity__gt=0,
        ).order_by('-created_at')

    def get_serializer_class(self):
        if self.action in ('create', 'update', 'partial_update'):
            return ProductCreateSerializer
        return ProductSerializer

    def perform_create(self, serializer):
        if self.request.user.role != 'vendor' and not self.request.user.is_staff:
            raise permissions.PermissionDenied('Seuls les marchands peuvent ajouter des produits')
        serializer.save(vendor=self.request.user, is_approved=False)

    @action(detail=True, methods=['patch'])
    def update_product(self, request, pk=None):
        product = self.get_object()
        if product.vendor != request.user and not request.user.is_staff:
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        serializer = ProductCreateSerializer(product, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(ProductSerializer(product).data)

    @action(detail=False, methods=['post'], url_path='search_by_image')
    def search_by_image(self, request):
        """Search products by uploading an image. Uses perceptual hashing."""
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({'error': 'Aucune image fournie'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from PIL import Image
            import io

            def compute_hash(img):
                """Compute 64-bit average hash of an image."""
                img = img.convert('L').resize((8, 8), Image.LANCZOS)
                pixels = list(img.getdata())
                avg = sum(pixels) / len(pixels)
                bits = ''.join('1' if p > avg else '0' for p in pixels)
                return int(bits, 2)

            def hamming_distance(h1, h2):
                """Count differing bits between two hashes."""
                return bin(h1 ^ h2).count('1')

            # Compute hash of uploaded image
            uploaded = Image.open(io.BytesIO(image_file.read()))
            uploaded_hash = compute_hash(uploaded)

            # Compare against all approved products with images
            products = Product.objects.filter(
                is_approved=True,
                vendor__shop__is_active=True,
                stock_quantity__gt=0,
            ).exclude(image='').exclude(image__isnull=True)

            matches = []
            threshold = 12  # max differing bits (out of 64)
            for product in products:
                try:
                    product_img = Image.open(product.image.path)
                    product_hash = compute_hash(product_img)
                    distance = hamming_distance(uploaded_hash, product_hash)
                    if distance <= threshold:
                        matches.append({
                            'product': product,
                            'distance': distance,
                        })
                except Exception:
                    continue

            # Sort by closest match
            matches.sort(key=lambda m: m['distance'])

            # Serialize and return
            matched_products = [m['product'] for m in matches]
            serializer = ProductSerializer(matched_products, many=True, context={'request': request})
            return Response({'results': serializer.data, 'count': len(matched_products)})

        except Exception as e:
            return Response({'error': f'Erreur de traitement: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class MarketingRequestViewSet(viewsets.ModelViewSet):
    queryset = MarketingRequest.objects.all().order_by('-created_at')
    serializer_class = MarketingRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return MarketingRequest.objects.all().order_by('-created_at')
        if user.role == 'vendor':
            return MarketingRequest.objects.filter(vendor=user).order_by('-created_at')
        if user.role == 'influencer':
            return MarketingRequest.objects.filter(influencer=user).order_by('-created_at')
        return MarketingRequest.objects.none()

    def perform_create(self, serializer):
        if self.request.user.role != 'influencer':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Seuls les influenceurs peuvent envoyer des demandes')
        product = serializer.validated_data['product']
        serializer.save(influencer=self.request.user, vendor=product.vendor)

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        mr = self.get_object()
        if mr.vendor != request.user and not request.user.is_staff:
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        mr.status = 'accepted'
        mr.save()
        Notification.objects.create(
            user=mr.influencer,
            type='marketing_accepted',
            title='Demande acceptée !',
            body=f'{request.user.get_full_name() or request.user.username} a accepté votre demande pour « {mr.product.name} »',
            data={'product_name': mr.product.name, 'vendor_name': request.user.username, 'request_id': mr.id},
        )
        return Response(MarketingRequestSerializer(mr).data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        mr = self.get_object()
        if mr.vendor != request.user and not request.user.is_staff:
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        mr.status = 'rejected'
        mr.save()
        return Response(MarketingRequestSerializer(mr).data)

    @action(detail=False, methods=['get'])
    def accepted_products(self, request):
        """Return products accepted for the current influencer"""
        user = request.user
        if user.role != 'influencer':
            return Response([], status=status.HTTP_200_OK)
        accepted = MarketingRequest.objects.filter(influencer=user, status='accepted').select_related('product')
        products = [mr.product for mr in accepted]
        serializer = ProductSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def influencer_products(self, request):
        """Return accepted products for a specific influencer (by ?influencer_id=X)"""
        influencer_id = request.query_params.get('influencer_id')
        if not influencer_id:
            return Response([], status=status.HTTP_200_OK)
        accepted = MarketingRequest.objects.filter(
            influencer_id=influencer_id, status='accepted'
        ).select_related('product')
        products = [mr.product for mr in accepted]
        serializer = ProductSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)


class InfluencerAdViewSet(viewsets.ModelViewSet):
    queryset = InfluencerAd.objects.filter(is_active=True).order_by('-created_at')
    serializer_class = InfluencerAdSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        influencer_id = self.request.query_params.get('influencer_id')
        if influencer_id:
            all_qs = InfluencerAd.objects.filter(influencer_id=influencer_id)
            print(f"[InfluencerAd] customer={user.username} influencer_id={influencer_id} total={all_qs.count()}")
            return all_qs.order_by('-created_at')
        if user.is_staff or user.role == 'admin':
            return InfluencerAd.objects.all().order_by('-created_at')
        if user.role == 'influencer':
            qs = InfluencerAd.objects.filter(influencer=user)
            print(f"[InfluencerAd] influencer={user.username} id={user.pk} own_ads={qs.count()}")
            return qs.order_by('-created_at')
        return InfluencerAd.objects.filter(is_active=True).order_by('-created_at')

    def perform_create(self, serializer):
        if self.request.user.role != 'influencer':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Seuls les influenceurs peuvent créer des annonces')
        serializer.save(influencer=self.request.user, is_active=True)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.influencer != request.user and not request.user.is_staff:
            return Response({'error': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response({'success': True})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'success': True})

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'count': count})


class AdPurchaseViewSet(viewsets.ModelViewSet):
    serializer_class = AdPurchaseSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        return AdPurchase.objects.filter(buyer=self.request.user)

    def perform_create(self, serializer):
        buyer = self.request.user
        ad = serializer.validated_data['ad']
        amount = Decimal(str(ad.price))
        platform_share = amount * Decimal('0.05')
        influencer_share = amount - platform_share
        if buyer.wallet_balance < amount:
            from rest_framework.exceptions import ValidationError
            raise ValidationError('Solde insuffisant pour acheter cette annonce.')
        with transaction.atomic():
            buyer.wallet_balance -= amount
            buyer.save(update_fields=['wallet_balance'])
            influencer = ad.influencer
            influencer.wallet_balance += influencer_share
            influencer.save(update_fields=['wallet_balance'])
            WalletTransaction.objects.create(
                user=buyer, amount=-amount, type='withdrawal',
                description=f"Achat annonce: {ad.description[:50]}"
            )
            WalletTransaction.objects.create(
                user=influencer, amount=influencer_share, type='sale',
                description=f"Vente annonce à {buyer.get_full_name() or buyer.username}: {ad.description[:40]}"
            )
            admin_user = User.objects.filter(role='admin').first()
            if admin_user and platform_share > 0:
                admin_user.wallet_balance += platform_share
                admin_user.save(update_fields=['wallet_balance'])
                WalletTransaction.objects.create(
                    user=admin_user, amount=platform_share, type='sale',
                    description=f"Frais plateforme annonce: {ad.description[:40]}"
                )
            serializer.save(buyer=buyer, amount=amount)
            Notification.objects.create(
                user=influencer,
                type='ad_purchase',
                title='Annonce achetée !',
                body=f'{buyer.get_full_name() or buyer.username} a acheté votre annonce ({amount} MRU)',
                data={
                    'buyer_name': buyer.get_full_name() or buyer.username,
                    'buyer_phone': buyer.phone or '',
                    'ad_id': ad.id,
                    'amount': str(amount),
                    'influencer_share': str(influencer_share),
                },
            )


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register_user(request):
    raw_data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
    email = (raw_data.get('email') or '').strip()
    username_source = (
        raw_data.get('username')
        or raw_data.get('full_name')
        or raw_data.get('first_name')
        or email
    ).strip()
    username_base = re.sub(r'[^\w.@+-]+', '_', username_source).strip('._-+@')
    if not username_base:
        username_base = (email.split('@')[0] if email else 'user') or 'user'
    username = username_base
    suffix = 1
    while User.objects.filter(username=username).exists():
        suffix += 1
        username = f'{username_base}_{suffix}'
    data = {
        'username': username,
        'email': email,
        'password': raw_data.get('password', ''),
        'role': raw_data.get('role', 'customer'),
        'full_name': raw_data.get('full_name', ''),
        'first_name': raw_data.get('first_name', ''),
        'last_name': raw_data.get('last_name', ''),
        'phone': raw_data.get('phone', ''),
        'address': raw_data.get('address', ''),
        'latitude': raw_data.get('latitude', ''),
        'longitude': raw_data.get('longitude', ''),
        'vehicle_type': raw_data.get('vehicle_type', ''),
        'vehicle_plate': raw_data.get('vehicle_plate', ''),
        'bank_account': raw_data.get('bank_account', ''),
        'resume': raw_data.get('resume', ''),
        'social_links': raw_data.get('social_links', ''),
        'specialty': raw_data.get('specialty', ''),
    }
    if raw_data.get('profile_image'):
        data['profile_image'] = raw_data.get('profile_image')
    if raw_data.get('vehicle_image'):
        data['vehicle_image'] = raw_data.get('vehicle_image')
    if raw_data.get('national_id'):
        data['national_id'] = raw_data.get('national_id')
    if raw_data.get('driving_license'):
        data['driving_license'] = raw_data.get('driving_license')

    serializer = UserRegistrationSerializer(data=data)
    if serializer.is_valid():
        user = serializer.save()
        if user.role == 'vendor':
            store_name = (raw_data.get('store_name') or '').strip()
            if store_name:
                shop_defaults = {
                    'name': store_name,
                    'description': (raw_data.get('store_description') or '').strip(),
                    'category': (raw_data.get('store_type') or '').strip() or None,
                }
                store_logo = request.FILES.get('store_logo')
                if store_logo:
                    shop_defaults['image'] = store_logo
                Shop.objects.update_or_create(
                    vendor=user,
                    defaults=shop_defaults,
                )
        return Response(
            {
                'success': True,
                'message': 'Compte créé avec succès. Votre compte sera activé après approbation de l\'administrateur.',
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'role': user.role,
                }
            },
            status=status.HTTP_201_CREATED
        )
    return Response(
        {'success': False, 'message': 'Veuillez vérifier les informations saisies', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def custom_login(request):
    """Custom login that checks is_approved before issuing JWT token.

    Accepts either:
      - phone + code (mobile app)
      - username + password (web admin fallback)
    """
    phone = (request.data.get('phone') or '').strip()
    code = request.data.get('code', '')
    username = (request.data.get('username') or '').strip()
    password = request.data.get('password', '')

    user = None

    if phone and code:
        # Try phone first, then fall back to username
        user = User.objects.filter(phone=phone).first()
        if user is None:
            user = User.objects.filter(username=phone).first()
        if user is None or not user.check_password(code):
            return Response(
                {'error': 'Identifiant ou code incorrect.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
    elif username and password:
        user = authenticate(username=username, password=password)
        if user is None:
            return Response(
                {'error': 'Nom d\'utilisateur ou mot de passe incorrect.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
    else:
        return Response(
            {'error': 'Veuillez fournir un numéro de téléphone et un code.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if not user.is_approved and not user.is_staff:
        return Response(
            {'error': 'Votre compte est en attente d\'approbation par l\'administrateur.'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Generate JWT tokens
    refresh = RefreshToken.for_user(user)
    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
    }, status=status.HTTP_200_OK)
