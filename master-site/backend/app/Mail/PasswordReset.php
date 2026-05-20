<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class PasswordReset extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public string $name, public string $resetUrl)
    {
    }

    public function build()
    {
        return $this->subject('Master.az — Şifrə bərpası / Сброс пароля')
            ->view('emails.password-reset')
            ->with(['name' => $this->name, 'resetUrl' => $this->resetUrl]);
    }
}
