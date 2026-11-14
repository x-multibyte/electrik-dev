<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Process;
use Tests\TestCase;

uses(TestCase::class);

it('passes valid reversible migrations and rejects migrations without down() or with DROP statements', function () {
    $script = base_path('.agents/skills/laravel-migration-validator/scripts/validate_migration.py');
    expect(is_file($script))->toBeTrue();

    $tmpDir = sys_get_temp_dir().'/electrik_mig_test_'.bin2hex(random_bytes(4));
    mkdir($tmpDir, 0777, true);

    $validFile = "{$tmpDir}/2026_11_11_000001_create_projects_table.php";
    file_put_contents($validFile, "<?php\nreturn new class {\npublic function up(): void {}\npublic function down(): void {}\n};\n");

    $passResult = Process::run(['python3', $script, $validFile]);
    expect($passResult->successful())->toBeTrue()
        ->and($passResult->output())->toContain('[OK]');

    $invalidFile = "{$tmpDir}/2026_11_11_000002_bad_migration.php";
    file_put_contents($invalidFile, "<?php\nreturn new class {\npublic function up(): void { DB::statement('DROP TABLE users'); }\n};\n");

    $failResult = Process::run(['python3', $script, $invalidFile]);
    expect($failResult->failed())->toBeTrue()
        ->and($failResult->output())->toContain('[MIGRATION_ERROR]');

    @unlink($validFile);
    @unlink($invalidFile);
    @rmdir($tmpDir);
});

it('rejects Schema::dropIfExists of core tables in up() or standalone drop migrations while allowing create_users down()', function () {
    $script = base_path('.agents/skills/laravel-migration-validator/scripts/validate_migration.py');

    $existingResult = Process::run(['python3', $script, base_path('database/migrations')]);
    expect($existingResult->successful())->toBeTrue()
        ->and($existingResult->output())->toContain('[OK]');

    $tmpDir = sys_get_temp_dir().'/electrik_mig_core_'.bin2hex(random_bytes(4));
    mkdir($tmpDir, 0777, true);

    $dropCoreInUp = "{$tmpDir}/2026_11_11_000003_drop_teams.php";
    file_put_contents($dropCoreInUp, "<?php\nreturn new class {\npublic function up(): void { Schema::dropIfExists('teams'); }\npublic function down(): void {}\n};\n");

    $failResult = Process::run(['python3', $script, $dropCoreInUp]);
    expect($failResult->failed())->toBeTrue()
        ->and($failResult->output())->toContain('[MIGRATION_ERROR]');

    @unlink($dropCoreInUp);
    @rmdir($tmpDir);
});

it('rejects ->truncate(), missing up(), and standalone Schema::dropIfExists in down()', function () {
    $script = base_path('.agents/skills/laravel-migration-validator/scripts/validate_migration.py');

    $tmpDir = sys_get_temp_dir().'/electrik_mig_extra_'.bin2hex(random_bytes(4));
    mkdir($tmpDir, 0777, true);

    $truncateFile = "{$tmpDir}/2026_11_11_000004_truncate_users.php";
    file_put_contents($truncateFile, "<?php\nreturn new class {\npublic function up(): void { DB::table('users')->truncate(); }\npublic function down(): void {}\n};\n");

    $truncateResult = Process::run(['python3', $script, $truncateFile]);
    expect($truncateResult->failed())->toBeTrue()
        ->and($truncateResult->output())->toContain('[MIGRATION_ERROR]');

    $missingUpFile = "{$tmpDir}/2026_11_11_000005_missing_up.php";
    file_put_contents($missingUpFile, "<?php\nreturn new class {\npublic function down(): void {}\n};\n");

    $missingUpResult = Process::run(['python3', $script, $missingUpFile]);
    expect($missingUpResult->failed())->toBeTrue()
        ->and($missingUpResult->output())->toContain('[MIGRATION_ERROR]');

    $standaloneDownDropFile = "{$tmpDir}/2026_11_11_000006_drop_teams_in_down.php";
    file_put_contents($standaloneDownDropFile, "<?php\nreturn new class {\npublic function up(): void {}\npublic function down(): void { Schema::dropIfExists('teams'); }\n};\n");

    $standaloneResult = Process::run(['python3', $script, $standaloneDownDropFile]);
    expect($standaloneResult->failed())->toBeTrue()
        ->and($standaloneResult->output())->toContain('[MIGRATION_ERROR]');

    @unlink($truncateFile);
    @unlink($missingUpFile);
    @unlink($standaloneDownDropFile);
    @rmdir($tmpDir);
});
