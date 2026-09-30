<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (request()->header('X-Forwarded-Proto') === 'https' || app()->environment('production')) {
            \Illuminate\Support\Facades\URL::forceScheme('https');
        }

        $dbPath = database_path('database.sqlite');
        if (!file_exists($dbPath) || filesize($dbPath) === 0) {
            $sourceDb = base_path('kebun_simulasi.sqlite');
            if (file_exists($sourceDb)) {
                copy($sourceDb, $dbPath);
            } else {
                touch($dbPath);
            }
        }
    }
}
