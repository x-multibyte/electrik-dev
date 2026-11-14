<?php

test('required php 8.5 extensions and sqlite connection work properly', function () {
    expect(PHP_VERSION)->toStartWith('8.5.')
        ->and(extension_loaded('mbstring'))->toBeTrue()
        ->and(extension_loaded('xml'))->toBeTrue()
        ->and(extension_loaded('curl'))->toBeTrue()
        ->and(extension_loaded('sqlite3'))->toBeTrue()
        ->and(extension_loaded('pdo_sqlite'))->toBeTrue()
        ->and(extension_loaded('dom'))->toBeTrue();
});
