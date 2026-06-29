"""
Django settings for backend project.
"""

from pathlib import Path
from datetime import timedelta
import os

# المسار الأساسي للمشروع
BASE_DIR = Path(__file__).resolve().parent.parent

# مفتاح الأمان 
SECRET_KEY = 'django-insecure-&@j=dg%8wt^5xi=o#p=z0gks7c474effilx*n=i54ed*qyy3&m'

# وضع التصحيح
DEBUG = True

# السماح بالوصول للسيرفر محلياً
ALLOWED_HOSTS = ['*'] if DEBUG else ['localhost', '192.168.200.204']

# التطبيقات المسجلة
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # المكتبات الإضافية
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'djoser',
    'rest_framework_simplejwt',
    
    # تطبيق المشروع
    'core',
]

# البرمجيات الوسيطة (Middleware)
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # يجب أن يكون دائماً في المقدمة لـ React
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    
    # --- [إضافة] الميدلوير الخاص بالمشرفين ---
    'core.middleware.AdminOnlyMiddleware', 
]

ROOT_URLCONF = 'backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'backend.wsgi.application'

# قاعدة البيانات (PostgreSQL)
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

# التحقق من كلمات المرور
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# الإعدادات الدولية
LANGUAGE_CODE = 'fr'
TIME_ZONE = 'UTC'
USE_I18N = True 
USE_TZ = True

# الملفات الثابتة والميديا
STATIC_URL = 'static/'
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# --- إعدادات CORS (مهمة جداً لـ React) ---
CORS_ALLOW_ALL_ORIGINS = True # لتسهيل التطوير حالياً
CORS_ALLOW_CREDENTIALS = True

# --- إعدادات DRF و JWT (النظام التقليدي) ---
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# --- إعدادات Djoser ---
DJOSER = {
    'LOGIN_FIELD': 'username',
    'USER_CREATE_PASSWORD_RETYPE': True,
    'SERIALIZERS': {
        'user_create': 'core.serializers.UserSerializer',
        'user': 'core.serializers.UserSerializer',
        'current_user': 'core.serializers.UserSerializer',
    },
}

# موديل المستخدم المخصص
AUTH_USER_MODEL = 'core.User'

# عملة العرض الافتراضية في التطبيق
DEFAULT_CURRENCY = 'MRU'