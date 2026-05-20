<!doctype html>
<html>
<head><meta charset="utf-8"><title>{{ $title }}</title></head>
<body style="font-family: -apple-system, sans-serif; background:#f5f5f5; margin:0; padding:24px;">
  <div style="max-width:560px; margin:0 auto; background:#fff; border-radius:12px; padding:32px;">
    <h2 style="margin:0 0 8px; font-size:20px;">{{ $title }}</h2>
    @if($name)
      <p style="margin:0 0 16px; color:#666; font-size:14px;">{{ $name }}!</p>
    @endif
    <p style="font-size:15px; line-height:1.6; color:#333; margin:0 0 24px;">{{ $body }}</p>
    @if($actionUrl)
      <p style="margin:0 0 24px;">
        <a href="{{ $actionUrl }}" style="display:inline-block; background:#2563eb; color:#fff; padding:12px 24px; border-radius:8px; text-decoration:none; font-weight:600;">
          {{ $actionLabel ?? 'Открыть' }}
        </a>
      </p>
    @endif
    <hr style="border:none; border-top:1px solid #eee; margin:24px 0;">
    <p style="font-size:12px; color:#999; margin:0;">
      Master.az — bütün ev xidmətləri tək yerdə.<br>
      <a href="{{ env('FRONTEND_URL') }}/notifications" style="color:#999;">Bildirişləri idarə et</a>
    </p>
  </div>
</body>
</html>
