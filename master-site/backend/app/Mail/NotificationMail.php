<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

/**
 * Generic notification email — used for order/proposal/application events.
 * Title + body come from NotificationService localized arrays.
 */
class NotificationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $title,
        public string $body,
        public string $name,
        public ?string $actionUrl = null,
        public ?string $actionLabel = null,
    ) {}

    public function build()
    {
        return $this->subject('Master.az — ' . $this->title)
            ->view('emails.notification')
            ->with([
                'title' => $this->title,
                'body' => $this->body,
                'name' => $this->name,
                'actionUrl' => $this->actionUrl,
                'actionLabel' => $this->actionLabel,
            ]);
    }
}
