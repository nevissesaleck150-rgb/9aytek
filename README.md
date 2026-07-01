# 9aytek — منصة التجارة المتكاملة

منصة تجارة إلكترونية متعددة الأدوار تجمع بين التجار، المؤثرين، الموصلين، والزبائن في نظام واحد متكامل. تتكون من ثلاثة تطبيقات: **واجهة موبايل Flutter**، **لوحة تحكم ويب React**، و**خادم خلفي Django REST**.

---

## فهرس المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [بنية المشروع](#بنية-المشروع)
3. [الأدوار والصلاحيات](#الأدوار-والصلاحيات)
4. [تدفق العمل الكامل](#تدفق-العمل-الكامل)
5. [الخادم الخلفي — Django REST](#الخادم-الخلفي--django-rest)
6. [لوحة التحكم — React Web Admin](#لوحة-التحكم--react-web-admin)
7. [تطبيق الموبايل — Flutter](#تطبيق-الموبايل--flutter)
8. [نظام توزيع الأرباح — BankilySplit](#نظام-توزيع-الأرباح--bankilysplit)
9. [الأمان والحماية](#الأمان-والحماية)
10. [قاعدة البيانات — PostgreSQL](#قاعدة-البيانات--postgresql)
11. [تثبيت وتشغيل المشروع](#تثبيت-وتشغيل-المشروع)
12. [المكتبات المستخدمة](#المكتبات-المستخدمة)

---

## نظرة عامة

**9aytek** منصة تجارية شاملة تعمل في موريتانيا، تسمح بـ:

- بيع **المنتجات المادية** عبر متاجر متعددة
- بيع **الخدمات الرقمية** (شحن تطبيقات + كورسات تعليمية)
- **التسويق بالعمولة** عبر المؤثرين
- **توصيل الطلبات** عبر موصلين مستقلين
- **الدفع عبر Bankily** (نظام الدفع الموريتاني)
- توزيع الأرباح **تلقائياً** على جميع الأطراف فور التسليم

---

## بنية المشروع

```
my_project/
├── backend/                    ← إعدادات Django (settings, urls, wsgi)
├── core/                       ← التطبيق الرئيسي
│   ├── models.py               ← 10 جداول قاعدة البيانات
│   ├── serializers.py          ← تحويل البيانات JSON ↔ Python
│   ├── views.py                ← منطق كل API Endpoint
│   ├── middleware.py           ← حماية مسارات المشرفين
│   └── migrations/             ← سجل تغييرات قاعدة البيانات
├── web_app/                    ← لوحة تحكم Admin (React)
│   └── src/
│       ├── pages/              ← Dashboard, Orders, Users, Finance...
│       └── components/         ← AppHeader, Sidebar
├── mobile_app/                 ← تطبيق الموبايل (Flutter)
│   └── lib/
│       ├── screens/dashboards/ ← 5 واجهات: Customer, Vendor, Influencer, Courier, Admin
│       ├── models/             ← User, ApiOrder, ApiProduct, NotificationItem...
│       ├── services/           ← api_service.dart (كل طلبات HTTP)
│       ├── widgets/            ← مكونات مشتركة
│       └── utils/              ← RoleRouter, BankilySplit, helpers
└── media/                      ← الصور المرفوعة (منتجات، بروفيلات، هوية وطنية)
```

---

## الأدوار والصلاحيات

| الدور | الوصول | ما يستطيع فعله |
|-------|--------|----------------|
| `admin` | لوحة الويب + موبايل | الموافقة على الحسابات والمنتجات، إدارة كل شيء، إحصائيات، مالية |
| `vendor` | موبايل فقط | إضافة منتجات، إدارة المتجر، تحضير الطلبات، قبول/رفض طلبات التسويق |
| `influencer` | موبايل فقط | طلب تسويق منتجات، نشر إعلانات، متابعة العمولات |
| `driver` | موبايل + ويب Delivery | قبول التوصيل، تتبع الطلب على الخريطة، تحديث حالة التوصيل |
| `customer` | موبايل فقط | تصفح المتاجر، إضافة للسلة، الدفع، متابعة الطلب |

> كل حساب جديد `is_approved=False` — يبقى مجمّداً حتى يوافق عليه المشرف.

---

## تدفق العمل الكامل

```
1. التسجيل والموافقة
   المستخدم يسجل → Admin يوافق → is_approved=True → يمكنه تسجيل الدخول

2. دورة حياة الطلب
   pending → paid → ready → on_way → arrived → delivered

3. توزيع الأرباح
   عند "delivered" → distribute_order_shares() → تحويل تلقائي لكل الأطراف
```

### تفصيل دورة الطلب:

```
[الزبون يضيف للسلة]
        ↓
[يدفع عبر Bankily] → status: pending → paid
        ↓
[التاجر يحضر الطلب] → status: ready
        ↓
[موصل يقبل التوصيل] → status: on_way → arrived
        ↓
[الزبون يؤكد الاستلام + تقييم] → status: delivered
        ↓
[توزيع الأرباح التلقائي]
   85% للتاجر | 10% للموصل | 5% للمنصة
   (أو 70% تاجر | 15% مؤثر | 10% موصل | 5% منصة — إذا كان عبر مؤثر)
```

---

## الخادم الخلفي — Django REST

### التقنيات المستخدمة

| المكتبة | الإصدار | الغرض |
|---------|---------|--------|
| Django | 6.0.4 | إطار العمل الأساسي |
| djangorestframework | 3.17.1 | بناء REST API |
| djangorestframework-simplejwt | 5.5.1 | المصادقة بـ JWT |
| djoser | 2.3.3 | endpoints جاهزة للمستخدمين |
| django-cors-headers | 4.9.0 | السماح لـ React بالوصول |
| psycopg2 | 2.9.11 | اتصال PostgreSQL |
| Pillow | 12.2.0 | معالجة الصور + البحث بالصورة |

### نقاط الـ API (Endpoints)

```
POST   /api/register/                        ← تسجيل حساب جديد (Multipart)
POST   /api/custom-login/                    ← تسجيل دخول بالهاتف + كود

GET    /api/users/                           ← قائمة المستخدمين
POST   /api/users/{id}/approve/              ← الموافقة على حساب
POST   /api/users/{id}/reject/               ← رفض حساب
GET    /api/users/dashboard_stats/           ← إحصائيات الـ Admin

GET    /api/products/                        ← قائمة المنتجات
POST   /api/products/                        ← إضافة منتج
POST   /api/products/search_by_image/        ← البحث بالصورة (aHash)

GET    /api/shops/                           ← قائمة المتاجر

GET    /api/orders/                          ← قائمة الطلبات (مفلترة بالدور)
POST   /api/orders/create_with_items/        ← إنشاء طلب
POST   /api/orders/{id}/confirm_bankily/     ← تأكيد الدفع
POST   /api/orders/{id}/accept_delivery/     ← قبول التوصيل
POST   /api/orders/{id}/update_status/       ← تحديث الحالة
POST   /api/orders/{id}/confirm_delivery/    ← تأكيد الاستلام + تقييم
POST   /api/orders/{id}/complete_topup/      ← إتمام شحن الرصيد (Admin)

GET    /api/services/                        ← الخدمات الرقمية
GET    /api/services/topup_requests/         ← طلبات الشحن المعلقة

GET    /api/marketing-requests/              ← طلبات التسويق
POST   /api/marketing-requests/              ← طلب تسويق من مؤثر
POST   /api/marketing-requests/{id}/accept/  ← التاجر يقبل
GET    /api/marketing-requests/accepted_products/ ← منتجات المؤثر المقبولة

GET    /api/influencer-ads/                  ← إعلانات المؤثرين
POST   /api/influencer-ads/                  ← نشر إعلان

GET    /api/ad-purchases/                    ← مشتريات الإعلانات
POST   /api/ad-purchases/                    ← شراء إعلان (خصم من المحفظة)

GET    /api/notifications/                   ← إشعارات المستخدم
POST   /api/notifications/mark_all_read/     ← تعليم الكل كمقروء
GET    /api/notifications/unread_count/      ← عدد غير المقروءة

GET    /api/finance/                         ← سجل المعاملات المالية (Admin فقط)
```

### جداول قاعدة البيانات (Models)

```python
User              ← المستخدمون (AbstractUser + role, wallet_balance, is_approved)
WalletTransaction ← سجل العمليات المالية (sale, withdrawal, refund)
Product           ← المنتجات المادية (مرتبطة بتاجر، تحتاج موافقة)
Shop              ← المتاجر (OneToOne مع التاجر، تُنشأ تلقائياً بـ Signal)
DigitalService    ← الخدمات الرقمية (topup | course)
Order             ← الطلبات (6 حالات من pending إلى delivered)
OrderItem         ← بنود الطلب (يحسب الحصص تلقائياً في save())
MarketingRequest  ← طلبات التسويق (influencer → vendor)
InfluencerAd      ← إعلانات المؤثرين للبيع
AdPurchase        ← شراء إعلان (خصم + تحويل فوري)
Notification      ← إشعارات النظام (5 أنواع)
```

### أنواع الإشعارات

| النوع | المستقبل | السبب |
|-------|---------|-------|
| `marketing_accepted` | المؤثر | التاجر قبل طلب التسويق |
| `wallet_credit` | المؤثر / الموصل | استلام أموال |
| `ad_purchase` | المؤثر | تاجر اشترى إعلانه (مع رقم هاتف المشتري) |
| `new_order` | كل الموصلين المتاحين | طلب جديد بانتظار التوصيل |
| `driver_rating` | الموصل | الزبون أعطاه تقييماً |

### Signals التلقائية

```python
# 1. إنشاء متجر تلقائياً عند تسجيل تاجر جديد
@receiver(post_save, sender=User)
def create_vendor_shop(...)

# 2. إشعار المؤثر/الموصل عند استلام أموال
@receiver(post_save, sender=WalletTransaction)
def notify_wallet_credit(...)
```

### Middleware المخصص

```python
class AdminOnlyMiddleware:
    # يحمي /api/finance/ ويتحقق من JWT + role='admin'
    # يعيد 403 للمستخدمين العاديين، 401 بدون توكن
```

---

## لوحة التحكم — React Web Admin

### التقنيات المستخدمة

| المكتبة | الإصدار | الغرض |
|---------|---------|--------|
| React | 19.2.5 | إطار واجهة المستخدم |
| react-router-dom | 7.14.1 | التنقل بين الصفحات |
| axios | 1.x | طلبات HTTP للـ API |

### الصفحات

#### `/` — تسجيل الدخول (Login)
- حقل اسم المستخدم وكلمة المرور
- يحفظ `access_token` في `localStorage`
- يتحقق من الدور ويوجه للـ Dashboard

#### `/dashboard` — لوحة الإحصائيات الرئيسية
- إجمالي الإيرادات، عدد الطلبات، المستخدمين النشطين
- مخطط شريطي SVG لأعلى المتاجر مبيعاً
- إحصائيات التوصيل والخدمات الرقمية
- جدول المستخدمين المعلقين مع أزرار الموافقة/الرفض
- جدول المنتجات بانتظار الموافقة

#### `/users` — إدارة المستخدمين
- عرض كل المستخدمين مع الصور والبيانات
- فلترة بالدور (vendor / influencer / driver / customer)
- موافقة أو رفض كل حساب
- عرض الهوية الوطنية ورخصة القيادة

#### `/orders` — إدارة الطلبات
- جدول كل الطلبات مع الحالات الملونة
- تغيير الحالة من `pending` إلى `delivered`
- تأكيد دفع Bankily اليدوي

#### `/topup` — إدارة شحن التطبيقات
- قائمة طلبات الشحن المدفوعة والمعلقة
- عرض: اسم الخدمة، معرف الحساب، المبلغ، الحالة
- زر تأكيد إتمام الشحن (`complete_topup`)

#### `/lms` — إدارة الكورسات
- عرض الكورسات المتاحة مع عدد الطلاب
- روابط المحتوى (محمية — تظهر للمشتري فقط)

#### `/finance` — المالية
- إجمالي الأموال المتداولة وأرباح المنصة
- جدول تفصيلي لكل معاملة: التاجر، المؤثر، الموصل، المنصة

#### `/delivery` — لوحة الموصل (ويب)
- مخصصة لواجهة الموصل على المتصفح
- عرض الطلبات المسندة إليه
- تحديث الحالة: `ready → on_way → arrived → delivered`

### مكونات مشتركة

**`AppHeader`** — يظهر في كل صفحة:
- عنوان الصفحة ومرحباً بالمستخدم
- جرس الإشعارات (مستخدمون معلقون + منتجات + طلبات شحن)
- النقر على الإشعار ينقل للصفحة المناسبة

**`Sidebar`** — شريط التنقل الجانبي:
- روابط كل الصفحات مع تمييز الصفحة النشطة

---

## تطبيق الموبايل — Flutter

### التقنيات المستخدمة

| المكتبة | الإصدار | الغرض |
|---------|---------|--------|
| flutter | SDK 3.9+ | إطار العمل الأساسي |
| http | ^1.1.0 | طلبات HTTP مع Fallback تلقائي |
| flutter_secure_storage | ^9.0.0 | تخزين JWT مشفر |
| provider | ^6.1.1 | إدارة حالة المستخدم |
| image_picker | ^1.0.7 | رفع الصور (معرض / كاميرا) |
| cached_network_image | ^3.3.1 | تحميل الصور بـ Cache |
| flutter_map | ^5.0.0 | خريطة تفاعلية OpenStreetMap |
| latlong2 | ^0.9.0 | إحداثيات GPS |
| geolocator | ^11.0.0 | تحديد الموقع اللحظي |
| flutter_polyline_points | ^2.0.0 | رسم مسار التوصيل |
| google_fonts | ^6.2.1 | خط Cairo الاحترافي |
| intl | 0.20.2 | تنسيق العملات والتواريخ |
| firebase_core | ^2.27.0 | خدمات Firebase |
| firebase_messaging | ^14.7.19 | Push Notifications |
| flutter_localizations | SDK | دعم اللغة الفرنسية |

### شاشات الموبايل

#### شاشة تسجيل الدخول (`login_screen.dart`)
- حقل رقم الهاتف + كود الدخول
- `custom_login` API مع فحص `is_approved`
- توجيه تلقائي بـ `RoleRouter.dashboardFor(user)`

#### شاشة التسجيل (`register_screen.dart`)
- نموذج ديناميكي يتغير حسب الدور المختار
- رفع Multipart: صورة بروفيل، هوية وطنية، رخصة قيادة، صورة مركبة
- حقول إضافية لكل دور (رقم اللوحة، اسم المتجر، الروابط الاجتماعية...)

#### واجهة الزبون — 4 تبويبات

| التبويب | المحتوى |
|---------|---------|
| الرئيسية | تصفح المتاجر حسب الفئة (5 فئات) + بحث |
| المتاجر | منتجات مع إضافة للسلة، إعلانات المؤثرين |
| طلباتي | تتبع الطلبات، تأكيد الاستلام + تقييم الموصل |
| البروفيل | تعديل البيانات، تسجيل الخروج |

السلة تُحفظ محلياً بـ `flutter_secure_storage` وتُستعاد عند إعادة الفتح.

البحث بالصورة: يرسل صورة للـ API ويعيد منتجات مشابهة (aHash algorithm).

#### واجهة التاجر — 3 تبويبات

| التبويب | المحتوى |
|---------|---------|
| منتجاتي | قائمة المنتجات + إضافة منتج جديد بصورة |
| الطلبات | طلبات العملاء مع زر "تجهيز الطلب" |
| الإحصائيات | رصيد المحفظة + إجمالي المبيعات |

Switch تفعيل/تعطيل المتجر مع نافذة تأكيد. طلبات التسويق من المؤثرين (قبول/رفض).

#### واجهة المؤثر — 4 تبويبات

| التبويب | المحتوى |
|---------|---------|
| البحث | تصفح المتاجر وطلب تسويق المنتجات |
| مساحتي | المنتجات المقبولة + إعلاناتي للبيع |
| الإحصائيات | رصيد المحفظة + عمولات الطلبات |
| البروفيل | تعديل البيانات + رابط المؤثر القابل للنسخ |

#### واجهة الموصل — 4 تبويبات

| التبويب | المحتوى |
|---------|---------|
| الطلبات | الطلبات المتاحة للقبول |
| الخريطة | مسار التوصيل (التاجر → الزبون) |
| الأرباح | رصيد المحفظة + سجل التوصيلات |
| البروفيل | بيانات المركبة + تسجيل الخروج |

Switch حالة أونلاين/أوفلاين مع نافذة تأكيد. قبول التوصيل يفتح الخريطة تلقائياً.

#### واجهة المشرف
- إحصائيات شاملة مع مخططات
- إدارة المستخدمين، المنتجات، الخدمات الرقمية
- سجل المعاملات المالية

### المكونات المشتركة (Widgets)

**`EditableProfileTab`** — تبويب تعديل البروفيل لكل الأدوار:
- 17 حقل نصي + اختيار الصور
- يُحدّث المتجر تلقائياً للتجار
- مُعزول كـ `StatefulWidget` منفصل لتجنب خطأ `_dependents.isEmpty`

**`showAppSnack()`** — إشعار Snackbar موحد (success / error / warning)

**`BankilyPaymentSheet`** — شاشة الدفع بـ 3 مراحل:
1. عرض المبلغ الإجمالي
2. معالجة الدفع (Loading)
3. عرض توزيع الأرباح على الأطراف

### الأدوات المساعدة (Utils)

**`RoleRouter`** — يوجه كل مستخدم لواجهته المناسبة:
```dart
static Widget dashboardFor(User user) {
    switch (user.role) {
        case 'vendor':     return VendorDashboard(user: user);
        case 'influencer': return InfluencerDashboard(user: user);
        case 'driver':     return CourierDashboard(user: user);
        case 'admin':      return AdminDashboard(user: user);
        default:           return CustomerDashboard(user: user);
    }
}
```

**`ApiService`** — نظام Fallback تلقائي للاتصال:
```dart
static List<String> _getBaseUrls() => [
    'http://$lanHost:$port/api',   // الشبكة المحلية
    'http://10.0.2.2:$port/api',  // Android Emulator
];
```

---

## نظام توزيع الأرباح — BankilySplit

### المعادلات

**منتج مادي — بدون مؤثر:**
```
التاجر:   85%
الموصل:   10%
المنصة:    5%
```

**منتج مادي — عبر مؤثر:**
```
التاجر:    70%
المؤثر:    15%
الموصل:    10%
المنصة:     5%
```

**خدمة رقمية (كورس أو شحن):**
```
المنصة:   100%
```

### الحماية من التكرار

```python
if order.is_shares_distributed:
    return  # منع التحويل مرتين لنفس الطلب

with transaction.atomic():  # كل أو لا شيء
    # توزيع الأرباح...
    order.is_shares_distributed = True
    order.save(update_fields=['is_shares_distributed'])
```

---

## الأمان والحماية

| الطبقة | الآلية | التفاصيل |
|--------|--------|---------|
| كلمات المرور | PBKDF2-SHA256 + Salt | `make_password()` من Django |
| المصادقة | JWT Bearer Token | Access: 60 دقيقة / Refresh: يوم |
| تجديد التوكن | `ROTATE_REFRESH_TOKENS=True` | كل استخدام ينتج Refresh Token جديد |
| صلاحيات API | `IsAuthenticated` افتراضياً | كل endpoint محمي إلا المستثنى صراحةً |
| حماية مسارات | `AdminOnlyMiddleware` | يحمي `/api/finance/` للـ admin فقط |
| CORS | `django-cors-headers` | يسمح لـ React بالوصول |
| SQL Injection | Django ORM | لا SQL يدوي — كل الاستعلامات عبر ORM |
| رفع الملفات | `ImageField` + Pillow | التحقق من نوع الملف |
| التوكن في الموبايل | `flutter_secure_storage` | مشفر في Keychain/Keystore |
| حماية روابط الكورسات | `to_representation()` | الرابط مخفي حتى يدفع المستخدم |
| موافقة الحسابات | `is_approved` | كل مستخدم جديد مجمّد حتى موافقة Admin |

---

## قاعدة البيانات — PostgreSQL

### إعدادات الاتصال

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'my_db',
        'USER': 'postgres',
        'PASSWORD': '123',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

### علاقات الجداول

```
User ──────────────── OneToOne  ──→ Shop
User ──────────────── ForeignKey ──→ Product (vendor)
User ──────────────── ForeignKey ──→ WalletTransaction
User ──────────────── ForeignKey ──→ Order (customer)
User ──────────────── ForeignKey ──→ Order (driver)
User ──────────────── ForeignKey ──→ InfluencerAd
User ──────────────── ForeignKey ──→ Notification
Order ─────────────── ForeignKey ──→ OrderItem
OrderItem ─────────── ForeignKey ──→ Product
OrderItem ─────────── ForeignKey ──→ DigitalService
OrderItem ─────────── ForeignKey ──→ User (influencer)
MarketingRequest ───── ForeignKey ──→ User (influencer) + User (vendor) + Product
AdPurchase ──────────  ForeignKey ──→ InfluencerAd + User (buyer)
```

---

## تثبيت وتشغيل المشروع

### متطلبات النظام

- Python 3.11+
- PostgreSQL 14+
- Node.js 18+
- Flutter SDK 3.9+

### 1. الخادم الخلفي (Django)

```bash
# إنشاء البيئة الافتراضية
python -m venv venv
venv\Scripts\activate           # Windows
# أو
source venv/bin/activate        # Linux/Mac

# تثبيت المكتبات
pip install -r requirements.txt

# إنشاء قاعدة البيانات في PostgreSQL
createdb my_db

# تطبيق الـ Migrations
python manage.py migrate

# إنشاء حساب مشرف
python manage.py createsuperuser

# تشغيل السيرفر
python manage.py runserver 0.0.0.0:8000
```

### 2. لوحة التحكم (React)

```bash
cd web_app
npm install
npm start
# يعمل على http://localhost:3000
```

### 3. تطبيق الموبايل (Flutter)

```bash
cd mobile_app

# تعديل عنوان السيرفر في:
# lib/config/api_config.dart → غيّر lanHost إلى IP جهازك

flutter pub get
flutter run
```

### 4. إعداد Firebase (للإشعارات الفورية)

1. أنشئ مشروع Firebase على [console.firebase.google.com](https://console.firebase.google.com)
2. حمّل `google-services.json` في `mobile_app/android/app/`
3. حمّل `GoogleService-Info.plist` في `mobile_app/ios/Runner/`

---

## المكتبات المستخدمة

### Python — Backend Django

| المكتبة | الإصدار | الغرض |
|---------|---------|--------|
| `Django` | 6.0.4 | إطار العمل الخلفي |
| `djangorestframework` | 3.17.1 | بناء REST API |
| `djangorestframework-simplejwt` | 5.5.1 | نظام JWT |
| `djoser` | 2.3.3 | endpoints جاهزة للمستخدمين |
| `django-cors-headers` | 4.9.0 | CORS للـ React |
| `psycopg2` | 2.9.11 | اتصال PostgreSQL |
| `Pillow` | 12.2.0 | معالجة الصور والبحث بالصورة |
| `social-auth-app-django` | 5.8.0 | OAuth (مطلوب بـ djoser) |
| `PyJWT` | 2.12.1 | ترميز وفك ترميز JWT |
| `cryptography` | 46.0.7 | تشفير البيانات الحساسة |

### JavaScript — React Web Admin

| المكتبة | الإصدار | الغرض |
|---------|---------|--------|
| `react` | 19.2.5 | إطار واجهة المستخدم |
| `react-router-dom` | 7.14.1 | التنقل بين الصفحات |
| `axios` | 1.x | طلبات HTTP |
| `react-scripts` | 5.0.1 | أدوات البناء |

### Dart — Flutter Mobile

| المكتبة | الإصدار | الغرض |
|---------|---------|--------|
| `http` | ^1.1.0 | طلبات HTTP مع Fallback |
| `flutter_secure_storage` | ^9.0.0 | تخزين JWT مشفر |
| `provider` | ^6.1.1 | إدارة الحالة |
| `image_picker` | ^1.0.7 | اختيار الصور |
| `cached_network_image` | ^3.3.1 | تحميل صور بـ Cache |
| `flutter_map` | ^5.0.0 | خرائط OpenStreetMap |
| `latlong2` | ^0.9.0 | إحداثيات GPS |
| `geolocator` | ^11.0.0 | تحديد الموقع اللحظي |
| `flutter_polyline_points` | ^2.0.0 | رسم مسار التوصيل |
| `google_fonts` | ^6.2.1 | خط Cairo |
| `intl` | 0.20.2 | تنسيق العملات والتواريخ |
| `firebase_messaging` | ^14.7.19 | Push Notifications |
| `flutter_localizations` | SDK | دعم اللغة الفرنسية |

---

## معلومات المشروع

| | |
|-|-|
| **اسم المشروع** | 9aytek |
| **النوع** | منصة تجارة إلكترونية متعددة الأدوار |
| **البيئة المستهدفة** | موريتانيا (عملة MRU، دفع Bankily) |
| **قاعدة البيانات** | PostgreSQL 14+ |
| **البروتوكول** | REST API + JWT Bearer Token |
| **المنصات** | Android، iOS، Web (Admin Panel) |
| **اللغة** | فرنسية (واجهة المستخدم) |
