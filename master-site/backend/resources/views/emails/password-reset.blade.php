<!doctype html>
<html>
<head><meta charset="utf-8"><title>Password reset</title></head>
<body style="font-family: -apple-system, sans-serif; background:#f5f5f5; margin:0; padding:24px;">
  <div style="max-width:560px; margin:0 auto; background:#fff; border-radius:12px; padding:32px;">
    <h2 style="margin:0 0 16px;">Salam, {{ $name }}!</h2>
    <p style="font-size:15px; line-height:1.6; color:#333;">
      Şifrəni sıfırlamaq üçün aşağıdakı düyməyə basın. Ссылка действительна 1 час.
    </p>
    <p style="margin:32px 0;">
      <a href="{{ $resetUrl }}" style="display:inline-block; background:#dc2626; color:#fff; padding:12px 24px; border-radius:8px; text-decoration:none; font-weight:600;">
        Şifrəni sıfırla / Сбросить пароль
      </a>
    </p>
    <p style="font-size:13px; color:#666;">
      Если кнопка не работает: <br>
      <a href="{{ $resetUrl }}" style="color:#dc2626; word-break:break-all;">{{ $resetUrl }}</a>
    </p>
    <hr style="border:none; border-top:1px solid #eee; margin:24px 0;">
    <p style="font-size:12px; color:#999; margin:0;">
      Если вы не запрашивали сброс пароля — просто проигнорируйте это письмо.
    </p>
  </div>
</body>
</html>
