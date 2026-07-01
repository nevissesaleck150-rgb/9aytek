from decimal import Decimal

from django.urls import reverse
from rest_framework.test import APITestCase

from .models import AdPurchase, InfluencerAd, Order, OrderItem, User, WalletTransaction


class InfluencerAdPlatformShareTests(APITestCase):
    def setUp(self):
        self.admin_user = User.objects.create_user(
            username='admin',
            password='pass',
            role='admin',
            wallet_balance=Decimal('0.00'),
        )
        self.influencer = User.objects.create_user(
            username='influencer',
            password='pass',
            role='influencer',
            phone='20600100',
            wallet_balance=Decimal('0.00'),
        )
        self.buyer = User.objects.create_user(
            username='buyer',
            password='pass',
            role='vendor',
            wallet_balance=Decimal('100.00'),
        )
        self.customer = User.objects.create_user(
            username='customer',
            password='pass',
            role='customer',
            wallet_balance=Decimal('100.00'),
        )
        self.ad = InfluencerAd.objects.create(
            influencer=self.influencer,
            description='Annonce test',
            price=100,
        )

    def test_ad_order_item_keeps_five_percent_for_platform(self):
        order = Order.objects.create(customer=self.buyer, total_amount=Decimal('100.00'))
        item = OrderItem.objects.create(order=order, influencer_ad=self.ad, quantity=1)

        self.assertEqual(item.platform_share, Decimal('5.00'))
        self.assertEqual(item.influencer_share, Decimal('95.00'))
        self.assertEqual(item.vendor_share, Decimal('0.00'))
        self.assertEqual(item.driver_share, Decimal('0.00'))

    def test_direct_ad_purchase_sends_five_percent_to_admin(self):
        self.client.force_authenticate(user=self.buyer)

        response = self.client.post(reverse('ad-purchase-list'), {'ad': self.ad.id})

        self.assertEqual(response.status_code, 201)
        self.buyer.refresh_from_db()
        self.influencer.refresh_from_db()
        self.admin_user.refresh_from_db()
        self.assertEqual(self.buyer.wallet_balance, Decimal('0.00'))
        self.assertEqual(self.influencer.wallet_balance, Decimal('95.00'))
        self.assertEqual(self.admin_user.wallet_balance, Decimal('5.00'))
        self.assertEqual(AdPurchase.objects.get().amount, Decimal('100.00'))
        self.assertTrue(
            WalletTransaction.objects.filter(
                user=self.admin_user,
                amount=Decimal('5.00'),
                description__startswith='Frais plateforme annonce',
            ).exists()
        )

    def test_customer_cannot_see_influencer_phone_before_paid_ad_order(self):
        order = Order.objects.create(
            customer=self.customer,
            total_amount=Decimal('100.00'),
            status='pending',
        )
        OrderItem.objects.create(order=order, influencer_ad=self.ad, quantity=1)
        self.client.force_authenticate(user=self.customer)

        response = self.client.get(reverse('order-list'))

        self.assertEqual(response.status_code, 200)
        item = response.data[0]['items'][0]
        self.assertIsNone(item['influencer_phone'])
        self.assertNotIn('platform_share', item)
        self.assertNotIn('influencer_share', item)

    def test_customer_can_see_influencer_phone_after_paid_ad_order(self):
        order = Order.objects.create(
            customer=self.customer,
            total_amount=Decimal('100.00'),
            status='paid',
        )
        OrderItem.objects.create(order=order, influencer_ad=self.ad, quantity=1)
        self.client.force_authenticate(user=self.customer)

        response = self.client.get(reverse('order-list'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data[0]['items'][0]['influencer_phone'], self.influencer.phone)

    def test_customer_ad_list_hides_phone_until_paid_purchase(self):
        self.client.force_authenticate(user=self.customer)

        before_response = self.client.get(reverse('influencer-ad-list'))
        self.assertEqual(before_response.status_code, 200)
        self.assertEqual(before_response.data[0]['influencer_phone'], '')

        self.client.post(reverse('ad-purchase-list'), {'ad': self.ad.id})
        after_response = self.client.get(reverse('influencer-ad-list'))

        self.assertEqual(after_response.status_code, 200)
        self.assertEqual(after_response.data[0]['influencer_phone'], self.influencer.phone)


class DashboardStatsTests(APITestCase):
    def test_incomplete_orders_counts_every_order_not_delivered(self):
        admin_user = User.objects.create_user(
            username='stats_admin',
            password='pass',
            role='admin',
            is_staff=True,
        )
        customer = User.objects.create_user(
            username='stats_customer',
            password='pass',
            role='customer',
        )
        for status in ['pending', 'paid', 'ready', 'on_way', 'arrived']:
            Order.objects.create(customer=customer, status=status)
        Order.objects.create(customer=customer, status='delivered')
        self.client.force_authenticate(user=admin_user)

        response = self.client.get(reverse('user-dashboard-stats'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['total_orders'], 6)
        self.assertEqual(response.data['incomplete_orders'], 5)
