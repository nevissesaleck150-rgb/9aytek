from django.contrib import admin
from .models import User, Product, DigitalService, Order, Shop, MarketingRequest, InfluencerAd

# تسجيل الجداول لتظهر في لوحة تحكم Django
admin.site.register(User)
admin.site.register(Product)
admin.site.register(DigitalService)
admin.site.register(Order)
admin.site.register(Shop)
admin.site.register(MarketingRequest)
admin.site.register(InfluencerAd)