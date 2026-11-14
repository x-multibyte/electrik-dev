<?php

require_once __DIR__.'/laravel_ai_shims.php';

use Electrik\Http\Middleware\BindTeamFromAccessToken;
use Electrik\Http\Middleware\SetLocale;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        then: function (): void {
            require base_path('routes/a2a.php');
        },
    )
    ->withMiddleware(function (Middleware $middleware): void {

        $middleware->web(append: [
            SetLocale::class,
        ]);
        $middleware->api(append: [
            BindTeamFromAccessToken::class,
        ]);
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );
    })->create();
