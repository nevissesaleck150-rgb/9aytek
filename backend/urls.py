from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from core.views import (
    UserViewSet, 
    FinanceViewSet, 
    DigitalServiceViewSet, 
    OrderViewSet,
    ProductViewSet,
    ShopViewSet,
    MarketingRequestViewSet,
    InfluencerAdViewSet,
    register_user,
    custom_login,
)

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'finance', FinanceViewSet, basename='finance')
router.register(r'services', DigitalServiceViewSet)
router.register(r'orders', OrderViewSet)
router.register(r'products', ProductViewSet)
router.register(r'shops', ShopViewSet)
router.register(r'marketing-requests', MarketingRequestViewSet, basename='marketing-request')
router.register(r'influencer-ads', InfluencerAdViewSet, basename='influencer-ad')

urlpatterns = [
    path('admin/', admin.site.urls), 
    
    path('api/', include(router.urls)),
    
    # --- Endpoint مخصص للتسجيل ---
    path('api/register/', register_user, name='register'),
    
    # --- Endpoint مخصص لتسجيل الدخول مع فحص الموافقة ---
    path('api/custom-login/', custom_login, name='custom_login'),
    
    # --- [العودة للنظام التقليدي] ---
    # الآن سنترك djoser يتعامل مع تسجيل الدخول بشكل افتراضي
    # ليعيد التوكن في جسم الرسالة (Response Body)
    path('api/auth/', include('djoser.urls')),
    path('api/auth/', include('djoser.urls.jwt')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)