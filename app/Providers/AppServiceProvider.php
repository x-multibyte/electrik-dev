<?php

declare(strict_types=1);

namespace App\Providers;

use App\Ai\SkillRegistry;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(SkillRegistry::class, function (): SkillRegistry {
            $registry = new SkillRegistry;
            foreach (glob(base_path('.agents/skills/*/SKILL.md')) ?: [] as $skillFile) {
                $skillName = basename(dirname($skillFile));
                $registry->register($skillName, $skillFile);
            }

            return $registry;
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
