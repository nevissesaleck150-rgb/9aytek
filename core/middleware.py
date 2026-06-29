from django.http import JsonResponse
from rest_framework_simplejwt.authentication import JWTAuthentication

class AdminOnlyMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # 1. استثناء الروابط التي لا تحتاج لفحص صلاحيات المشرف
        # استثنينا 'me' لكي يتمكن أي مستخدم من رؤية بروفايله
        # واستثنينا 'jwt/create' لكي يعمل تسجيل الدخول أصلاً
        exempt_paths = ['/api/auth/users/me/', '/api/auth/jwt/create/', '/api/auth/users/', '/api/custom-login/']
        
        if request.path in exempt_paths:
            return self.get_response(request)

        # 2. تطبيق الحماية على مسارات الإدارة فقط
        # يمكنك إضافة المسارات التي تريدين قصرها على المشرفين هنا
        protected_prefixes = ['/api/finance/']
        
        # Allow GET requests to /api/users/ (view handles role-based filtering)
        if request.path.startswith('/api/users/') and request.method == 'GET':
            return self.get_response(request)
        
        is_protected = any(request.path.startswith(prefix) for prefix in protected_prefixes)

        if is_protected:
            try:
                auth = JWTAuthentication()
                user_auth_tuple = auth.authenticate(request)
                
                if user_auth_tuple is not None:
                    user, token = user_auth_tuple
                    # التحقق من الرول (Role) بناءً على موديل المستخدم الخاص بكِ
                    if not user.is_staff and getattr(user, 'role', '') != 'admin':
                        return JsonResponse({'error': 'Access denied. Admins only.'}, status=403)
                else:
                    # إذا كان المسار محمياً ولا يوجد توكن
                    return JsonResponse({'error': 'Authentication required.'}, status=401)
            except Exception:
                return JsonResponse({'error': 'Invalid token or authentication error.'}, status=401)

        return self.get_response(request)