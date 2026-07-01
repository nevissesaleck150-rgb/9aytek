from django.db import models
from django.contrib.auth.models import AbstractUser
from decimal import Decimal
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.db import transaction

# 1. المستخدمين (User Model)
class User(AbstractUser):
    ROLE_CHOICES = (
        ('admin', 'Admin/SuperAdmin'),
        ('vendor', 'Vendor/Merchant'),
        ('influencer', 'Influencer'),
        ('driver', 'Delivery Driver'),
        ('customer', 'Customer'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='customer')
    phone = models.CharField(max_length=15, blank=True)
    address = models.TextField(blank=True, null=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    wallet_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    profile_image = models.ImageField(upload_to='profiles/', blank=True, null=True)
    vehicle_type = models.CharField(max_length=120, blank=True)
    vehicle_plate = models.CharField(max_length=50, blank=True)
    vehicle_image = models.ImageField(upload_to='vehicles/', blank=True, null=True)

    # حقول إضافية يتم جمعها أثناء التسجيل وعرضها للمشرف
    bank_account = models.CharField(max_length=120, blank=True)
    national_id = models.ImageField(upload_to='national_ids/', blank=True, null=True)
    driving_license = models.ImageField(upload_to='licenses/', blank=True, null=True)
    resume = models.TextField(blank=True)
    social_links = models.TextField(blank=True)
    specialty = models.CharField(max_length=255, blank=True)

    # حقل التفعيل الخاص بالمرحلة الثانية
    is_approved = models.BooleanField(default=False) 

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"

# 2. سجل العمليات المالية (Transaction History)
class WalletTransaction(models.Model):
    TRANSACTION_TYPES = (
        ('sale', 'Vente/Sale'),
        ('withdrawal', 'Retrait/Withdrawal'),
        ('refund', 'Remboursement/Refund'),
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.amount} MRU ({self.type})"

# 3. جدول المنتجات المدمج
class Product(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    vendor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='products', limit_choices_to={'role': 'vendor'})
    stock_quantity = models.PositiveIntegerField(default=0)
    color = models.CharField(max_length=50, blank=True, null=True)
    size = models.CharField(max_length=50, blank=True, null=True)
    material = models.CharField(max_length=100, blank=True, null=True)
    technical_specs = models.TextField(blank=True, null=True)
    is_approved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

# 4. جدول المتاجر والبوتيكات
class Shop(models.Model):
    vendor = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='shop',
        limit_choices_to={'role': 'vendor'}
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=120, blank=True, null=True)
    image = models.ImageField(upload_to='shops/', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

# 5. جدول الخدمات الرقمية
class DigitalService(models.Model):
    SERVICE_TYPES = (('topup', 'App Recharge'), ('course', 'Online Course'))
    type = models.CharField(max_length=10, choices=SERVICE_TYPES)
    title = models.CharField(max_length=255)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    vendor = models.ForeignKey(User, on_delete=models.CASCADE, null=True, limit_choices_to={'role': 'vendor'})
    required_field_name = models.CharField(max_length=100, help_text="e.g. User ID for topup")
    content_link = models.URLField(blank=True, null=True)
    image = models.ImageField(upload_to='courses/', blank=True, null=True)

    def __str__(self):
        return self.title

# 5. جدول الطلبات الكلي
class Order(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending Payment'),
        ('paid', 'Paid'),
        ('ready', 'Ready for Pick'),
        ('on_way', 'On the Way'),
        ('arrived', 'Arrived to Customer'),
        ('delivered', 'Delivered'),
    )
    customer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='my_orders')
    driver = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='deliveries')
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    driver_rating = models.PositiveIntegerField(null=True, blank=True)
    is_shares_distributed = models.BooleanField(default=False)
    is_disbursed = models.BooleanField(default=False)
    # Delivery locations
    vendor_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    vendor_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    customer_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    customer_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    delivery_address = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Order #{self.id} - {self.customer.username if self.customer else 'Unknown'}"

# 6. تفاصيل الطلب وتوزيع الأموال
class OrderItem(models.Model):
    order = models.ForeignKey(Order, related_name='items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, null=True, blank=True)
    digital_service = models.ForeignKey(DigitalService, on_delete=models.CASCADE, null=True, blank=True)
    influencer_ad = models.ForeignKey('InfluencerAd', on_delete=models.CASCADE, null=True, blank=True)
    influencer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, limit_choices_to={'role': 'influencer'})
    quantity = models.PositiveIntegerField(default=1)
    vendor_ready = models.BooleanField(default=False, help_text="Vendor has marked this item ready")
    topup_account_id = models.CharField(max_length=255, null=True, blank=True)
    topup_payer = models.CharField(max_length=255, null=True, blank=True)
    topup_recharge_type = models.CharField(max_length=100, null=True, blank=True)
    
    vendor_share = models.DecimalField(max_digits=10, decimal_places=2, editable=False)
    influencer_share = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, editable=False)
    platform_share = models.DecimalField(max_digits=10, decimal_places=2, editable=False)
    driver_share = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, editable=False)

    def save(self, *args, **kwargs):
        if self.product:
            raw_price = self.product.price
        elif self.digital_service:
            raw_price = self.digital_service.price
        else:
            raw_price = self.influencer_ad.price
        unit_price = Decimal(str(raw_price))
        total_item_price = unit_price * self.quantity
        if self.influencer_ad:
            self.platform_share = total_item_price * Decimal('0.05')
            self.vendor_share = Decimal('0.00')
            self.influencer_share = total_item_price - self.platform_share
            self.driver_share = Decimal('0.00')
            if not self.influencer:
                self.influencer = self.influencer_ad.influencer
        elif self.digital_service:
            # Digital service (LMS course or topup) -> 100% platform
            self.platform_share = total_item_price
            self.vendor_share = Decimal('0.00')
            self.influencer_share = Decimal('0.00')
            self.driver_share = Decimal('0.00')
        else:
            # Physical product -> Courier 10%, Platform 5%
            self.driver_share = total_item_price * Decimal('0.10')
            self.platform_share = total_item_price * Decimal('0.05')
            if self.influencer:
                # Influencer marketing -> Vendor 70%, Influencer 15%
                self.influencer_share = total_item_price * Decimal('0.15')
                self.vendor_share = total_item_price * Decimal('0.70')
            else:
                # Direct Vendor -> Vendor 85%
                self.influencer_share = Decimal('0.00')
                self.vendor_share = total_item_price * Decimal('0.85')
        super().save(*args, **kwargs)

def distribute_order_shares(order):
    """توزيع الحصص على المحافظ عند اكتمال الطلب."""
    if order.is_shares_distributed:
        return
    with transaction.atomic():
        for instance in order.items.all():
            vendor = instance.product.vendor if instance.product else getattr(instance.digital_service, 'vendor', None)
            if vendor and instance.vendor_share > 0:
                vendor.wallet_balance += instance.vendor_share
                vendor.save(update_fields=['wallet_balance'])
                WalletTransaction.objects.create(
                    user=vendor, amount=instance.vendor_share, type='sale',
                    description=f"Vente de: {instance.product or instance.digital_service} (Commande #{order.id})"
                )
            if instance.influencer and instance.influencer_share > 0:
                instance.influencer.wallet_balance += instance.influencer_share
                instance.influencer.save(update_fields=['wallet_balance'])
                promoted_item = instance.product or instance.digital_service or instance.influencer_ad
                WalletTransaction.objects.create(
                    user=instance.influencer, amount=instance.influencer_share, type='sale',
                    description=f"Commission sur: {promoted_item} (Commande #{order.id})"
                )
            if order.driver and instance.driver_share > 0:
                order.driver.wallet_balance += instance.driver_share
                order.driver.save(update_fields=['wallet_balance'])
                WalletTransaction.objects.create(
                    user=order.driver, amount=instance.driver_share, type='sale',
                    description=f"Livraison (Commande #{order.id})"
                )
            admin_user = User.objects.filter(role='admin').first()
            if admin_user and instance.platform_share > 0:
                admin_user.wallet_balance += instance.platform_share
                admin_user.save(update_fields=['wallet_balance'])
                WalletTransaction.objects.create(
                    user=admin_user, amount=instance.platform_share, type='sale',
                    description=f"Frais plateforme Commande #{order.id}"
                )
        order.is_shares_distributed = True
        order.save(update_fields=['is_shares_distributed'])

# 7. طلبات التسويق من المؤثرين
class MarketingRequest(models.Model):
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('accepted', 'Acceptée'),
        ('rejected', 'Rejetée'),
    )
    influencer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='marketing_requests_sent', limit_choices_to={'role': 'influencer'})
    vendor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='marketing_requests_received', limit_choices_to={'role': 'vendor'})
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='marketing_requests')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('influencer', 'product')

    def __str__(self):
        return f"{self.influencer.username} -> {self.product.name} ({self.status})"


# 8. إعلانات المؤثرين
class InfluencerAd(models.Model):
    influencer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='ads',
        limit_choices_to={'role': 'influencer'}
    )
    description = models.TextField()
    price = models.PositiveIntegerField(default=0)
    image = models.ImageField(upload_to='ads/', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Annonce de {self.influencer.username} - {self.price} MRU"


# 9. شراء إعلانات المؤثرين من طرف التجار
class AdPurchase(models.Model):
    ad = models.ForeignKey(InfluencerAd, on_delete=models.CASCADE, related_name='purchases')
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ad_purchases')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.buyer.username} → {self.ad.description[:40]}"


# 10. الإشعارات
class Notification(models.Model):
    TYPE_CHOICES = [
        ('marketing_accepted', 'Demande marketing acceptée'),
        ('wallet_credit', 'Argent reçu'),
        ('ad_purchase', 'Annonce achetée'),
        ('new_order', 'Nouvelle commande'),
        ('driver_rating', 'Avis client'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    type = models.CharField(max_length=30, choices=TYPE_CHOICES)
    title = models.CharField(max_length=255)
    body = models.TextField()
    data = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} – {self.title}"


# Auto-create Shop for new vendors
@receiver(post_save, sender=User)
def create_vendor_shop(sender, instance, created, **kwargs):
    if created and instance.role == 'vendor':
        Shop.objects.get_or_create(vendor=instance, defaults={'name': instance.username, 'is_active': True})


# Notify influencer or driver when wallet is credited
@receiver(post_save, sender=WalletTransaction)
def notify_wallet_credit(sender, instance, created, **kwargs):
    if created and instance.amount > 0 and instance.user.role in ('influencer', 'driver'):
        Notification.objects.create(
            user=instance.user,
            type='wallet_credit',
            title='Argent reçu !',
            body=f'+{instance.amount} MRU · {instance.description}',
            data={'amount': str(instance.amount)},
        )
