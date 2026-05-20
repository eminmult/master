<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class EmailVerification extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public string $name, public string $verifyUrl)
    {
    }

    public function build()
    {
        return $this->subject('Master.az — Email təsdiqi / Подтверждение email')
            ->view('emails.verify-email')
            ->with(['name' => $this->name, 'verifyUrl' => $this->verifyUrl]);
    }
}
