<!doctype html>
<html>
<head><meta charset="utf-8"><title>Email verification</title></head>
<body style="font-family: -apple-system, sans-serif; background:#f5f5f5; margin:0; padding:24px;">
  <div style="max-width:560px; margin:0 auto; background:#fff; border-radius:12px; padding:32px;">
    <h2 style="margin:0 0 16px;">Salam, {{ $name }}!</h2>
    <p style="font-size:15px; line-height:1.6; color:#333;">
      Master.az hesabınızı təsdiq etmək üçün aşağıdakı düyməyə basın. Ссылка действительна 24 часа.
    </p>
    <p style="margin:32px 0;">
      <a href="{{ $verifyUrl }}" style="display:inline-block; background:#2563eb; color:#fff; padding:12px 24px; border-radius:8px; text-decoration:none; font-weight:600;">
        Təsdiq et / Подтвердить
      </a>
    </p>
    <p style="font-size:13px; color:#666;">
      Если кнопка не работает: <br>
      <a href="{{ $verifyUrl }}" style="color:#2563eb; word-break:break-all;">{{ $verifyUrl }}</a>
    </p>
    <hr style="border:none; border-top:1px solid #eee; margin:24px 0;">
    <p style="font-size:12px; color:#999; margin:0;">
      Bu məktubu siz istəməmisinizsə, ona məhəl qoymayın.
    </p>
  </div>
</body>
</html>
