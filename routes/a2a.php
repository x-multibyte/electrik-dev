<?php

declare(strict_types=1);

use App\Ai\A2a\A2aServerController;
use Illuminate\Support\Facades\Route;

Route::get('/.well-known/agent.json', [A2aServerController::class, 'agentCard'])
    ->name('a2a.agent-card');

Route::middleware('api')
    ->post('/api/a2a/tasks/send', [A2aServerController::class, 'handleTask'])
    ->name('a2a.tasks.send');
