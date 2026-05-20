<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AddressController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $addresses = $request->user()->addresses()->orderByDesc('is_default')->orderByDesc('created_at')->get();
        return response()->json(['addresses' => $addresses]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'label' => 'nullable|string|max:50',
            'full_address' => 'required|string|max:500',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'entrance' => 'nullable|string|max:20',
            'floor' => 'nullable|string|max:10',
            'intercom' => 'nullable|string|max:20',
            'note' => 'nullable|string|max:500',
            'is_default' => 'boolean',
        ]);

        $address = DB::transaction(function () use ($request, $data) {
            if (!empty($data['is_default'])) {
                $request->user()->addresses()->update(['is_default' => false]);
            }
            // First address is always default
            if (!$request->user()->addresses()->exists()) {
                $data['is_default'] = true;
            }
            return $request->user()->addresses()->create($data);
        });

        return response()->json(['address' => $address], 201);
    }

    public function update(Request $request, Address $address): JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $data = $request->validate([
            'label' => 'nullable|string|max:50',
            'full_address' => 'required|string|max:500',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'entrance' => 'nullable|string|max:20',
            'floor' => 'nullable|string|max:10',
            'intercom' => 'nullable|string|max:20',
            'note' => 'nullable|string|max:500',
            'is_default' => 'boolean',
        ]);

        if (!empty($data['is_default'])) {
            $request->user()->addresses()->where('id', '!=', $address->id)->update(['is_default' => false]);
        }

        $address->update($data);

        return response()->json(['address' => $address]);
    }

    public function destroy(Request $request, Address $address): JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'İcazə yoxdur.'], 403);
        }

        $wasDefault = $address->is_default;
        $address->delete();

        if ($wasDefault) {
            $request->user()->addresses()->first()?->update(['is_default' => true]);
        }

        return response()->json(['message' => 'Silindi.']);
    }
}
