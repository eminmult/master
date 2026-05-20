<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientController extends Controller
{
    public function updateProfile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'nullable|string|max:100',
            'email' => 'nullable|email|unique:users,email,' . $request->user()->id,
        ]);

        $request->user()->update($data);

        return response()->json(['user' => $request->user()->fresh()]);
    }
}
