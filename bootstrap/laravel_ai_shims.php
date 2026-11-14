<?php

declare(strict_types=1);

namespace Laravel\Ai\Contracts {
    use Illuminate\Contracts\JsonSchema\JsonSchema;
    use Laravel\Ai\Tools\Request;
    use Stringable;

    if (! interface_exists(Agent::class)) {
        interface Agent
        {
            public function instructions(): Stringable|string;
        }
    }

    if (! interface_exists(HasTools::class)) {
        interface HasTools
        {
            /**
             * @return iterable<int, object>
             */
            public function tools(): iterable;
        }
    }

    if (! interface_exists(Tool::class)) {
        interface Tool
        {
            public function description(): Stringable|string;

            public function handle(Request $request): Stringable|string;

            /**
             * @return array<string, mixed>
             */
            public function schema(JsonSchema $schema): array;
        }
    }
}

namespace Laravel\Ai\Tools {
    use ArrayAccess;
    use LogicException;

    if (! class_exists(Request::class)) {
        /**
         * @implements ArrayAccess<string, mixed>
         */
        class Request implements ArrayAccess
        {
            /**
             * @param  array<string, mixed>  $arguments
             */
            public function __construct(
                private array $arguments = [],
            ) {}

            public function offsetExists(mixed $offset): bool
            {
                return array_key_exists((string) $offset, $this->arguments);
            }

            public function offsetGet(mixed $offset): mixed
            {
                return $this->arguments[(string) $offset] ?? null;
            }

            public function offsetSet(mixed $offset, mixed $value): void
            {
                if ($offset === null) {
                    throw new LogicException('Tool request arguments require string keys.');
                }

                $this->arguments[(string) $offset] = $value;
            }

            public function offsetUnset(mixed $offset): void
            {
                unset($this->arguments[(string) $offset]);
            }
        }
    }
}

namespace Laravel\Ai\Enums {
    if (! enum_exists(Lab::class)) {
        enum Lab: string
        {
            case Gemini = 'gemini';
            case OpenAI = 'openai';
            case Anthropic = 'anthropic';
        }
    }
}

namespace Laravel\Ai\Attributes {
    use Attribute;
    use Laravel\Ai\Enums\Lab;

    if (! class_exists(Provider::class)) {
        #[Attribute(Attribute::TARGET_CLASS)]
        final class Provider
        {
            public function __construct(
                public readonly Lab $provider,
            ) {}
        }
    }

    if (! class_exists(Model::class)) {
        #[Attribute(Attribute::TARGET_CLASS)]
        final class Model
        {
            public function __construct(
                public readonly string $model,
            ) {}
        }
    }

    if (! class_exists(MaxSteps::class)) {
        #[Attribute(Attribute::TARGET_CLASS)]
        final class MaxSteps
        {
            public function __construct(
                public readonly int $steps,
            ) {}
        }
    }
}

namespace Laravel\Ai {
    use Stringable;

    if (! trait_exists(Promptable::class)) {
        trait Promptable
        {
            public function prompt(string $prompt): Stringable|string
            {
                if (method_exists($this, 'instructions')) {
                    $this->instructions();
                }

                return 'Electrik Tenant Copilot response: '.$prompt;
            }
        }
    }
}
