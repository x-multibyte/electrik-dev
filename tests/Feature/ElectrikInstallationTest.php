<?php

declare(strict_types=1);

use App\Models\User;
use Electrik\Concerns\ExportsElectrikPersonalData;
use Electrik\ElectrikServiceProvider;
use Electrik\Models\Permission;
use Electrik\Models\Role;
use Electrik\Models\Team;
use Illuminate\Support\Facades\Route;
use Laravel\Cashier\Billable;
use Laravel\Passkeys\PasskeyAuthenticatable;
use Laravel\Sanctum\HasApiTokens;
use Mpociot\Teamwork\Traits\UserHasTeams;
use Rappasoft\LaravelAuthenticationLog\Traits\AuthenticationLoggable;
use Spatie\Permission\Traits\HasRoles;

it('installs electrik 5.x as a composer dependency and registers vendor classes', function () {
    $composer = json_decode((string) file_get_contents(base_path('composer.json')), true, 512, JSON_THROW_ON_ERROR);

    expect($composer['require'])->toHaveKey('electrik/electrik')
        ->and($composer['require']['electrik/electrik'])->toContain('^5.5')
        ->and(class_exists(ElectrikServiceProvider::class))->toBeTrue()
        ->and(class_exists(Team::class))->toBeTrue();
});

it('publishes electrik, teamwork, and team-scoped permission configs', function () {
    expect(is_file(config_path('electrik.php')))->toBeTrue()
        ->and(is_file(config_path('teamwork.php')))->toBeTrue()
        ->and(is_file(config_path('permission.php')))->toBeTrue()
        ->and(config('teamwork.team_model'))->toBe(Team::class)
        ->and(config('permission.teams'))->toBeTrue()
        ->and(config('permission.models.permission'))->toBe(Permission::class)
        ->and(config('permission.models.role'))->toBe(Role::class);
});

it('wires electrik traits on App\\Models\\User without Cashier Billable', function () {
    $traits = class_uses_recursive(User::class);

    expect($traits)->toContain(
        UserHasTeams::class,
        HasRoles::class,
        HasApiTokens::class,
        ExportsElectrikPersonalData::class,
        PasskeyAuthenticatable::class,
        AuthenticationLoggable::class,
    )->and($traits)->not->toContain(Billable::class);
});

it('keeps auth, teams, billing, and ops in vendor rather than dumping into App', function () {
    $webRoutes = (string) file_get_contents(base_path('routes/web.php'));

    expect(is_dir(app_path('Http/Controllers/Auth')))->toBeFalse()
        ->and(is_file(app_path('Models/Team.php')))->toBeFalse()
        ->and(class_exists('App\\Models\\Team'))->toBeFalse()
        ->and($webRoutes)->not->toContain('/login')
        ->and($webRoutes)->not->toContain('/register')
        ->and($webRoutes)->not->toContain('/billing')
        ->and($webRoutes)->not->toContain('/ops');

    expect(Route::has('login'))->toBeTrue()
        ->and(Route::has('register'))->toBeTrue()
        ->and(Route::has('dashboard'))->toBeTrue()
        ->and(Route::has('billing.index'))->toBeTrue()
        ->and(Route::has('teams.index'))->toBeTrue()
        ->and(Route::has('ops.dashboard'))->toBeTrue();
});

it('wires Electrik Slate 3 CSS and view sources in resources/css/app.css', function () {
    $css = (string) file_get_contents(resource_path('css/app.css'));

    expect($css)
        ->toContain('vendor/electrik/slate/resources/css/slate.css')
        ->toContain('vendor/electrik/slate/resources/views')
        ->toContain('vendor/electrik/electrik/resources/views');
});

it('serves login and register screens from the vendor Electrik shell', function () {
    $this->get('/login')->assertOk();
    $this->get('/register')->assertOk();
});
