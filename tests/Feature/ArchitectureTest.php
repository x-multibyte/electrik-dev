<?php

declare(strict_types=1);

arch()->preset()->php();
arch()->preset()->security();
arch()->preset()->laravel();

arch('strict types and no debug calls in app')
    ->expect('App')
    ->toUseStrictTypes()
    ->not->toUse(['dd', 'dump', 'die', 'var_dump', 'ray']);

arch('no forbidden abstraction layers that cause agent drift')
    ->expect([
        'App\Services',
        'App\Repositories',
        'App\Actions',
    ])
    ->not->toBeClasses()
    ->not->toBeInterfaces()
    ->not->toBeTraits()
    ->not->toBeEnums()
    ->not->toBeUsed();

arch('controllers follow naming and cohesion conventions')
    ->expect('App\Http\Controllers')
    ->toHaveSuffix('Controller');
