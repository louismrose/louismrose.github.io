---
layout: post
title: Debugging non-deterministic tests in PHPUnit
---

You have a test that fails when run as part of your test suite. You re-run the test on its own, and it passes. What gives? More than likely you have a [non-deterministic test](https://martinfowler.com/articles/nonDeterminism.html), and probably a test that lacks isolation.

Here's a tip for debugging tests that are breaking isolation: a PHPUnit Listener can check which of your test cases is changing the environment and causing a failure of a later test case. For example, suppose your tests rely on the `APP_ENV` environment variable being set to `test`. The following PHPUnit listener will check this before every test:

```php
class AppEnvIsTestListener extends PHPUnit_Framework_BaseTestListener
{

  public function startTest(PHPUnit_Framework_Test $test) {
    if (getenv("APP_ENV") !== "test") {
      echo "A prior test has changed APP_ENV!\n";
    }
  }
}
```

To use the Listener, you'll need to add it to your `phpunit.xml`:

```xml
<phpunit>
  ...

  <listeners>
    <listener
      class="AppEnvIsTestListener"
      file="app/test/AppEnvIsTestListener.php"
    />
  </listeners>
</phpunit>
```

Combine this with the `--testdox` flag to `phpunit` and you'll get a very basic glimpse into which of your tests is leaking environment changes, and causing a later test to fail:

```sh
$ phpunit --filter EnvTest --testdox
PHPUnit 5.7.27 by Sebastian Bergmann and contributors.

Acme\EnvTest
 [x] Tests a thing
 [x] Tests another thing
A prior test has changed APP_ENV!
 [x] Tests a thing that does not depend on APP_ENV
A prior test has changed APP_ENV!
 [ ] Tests a thing that depends on APP_ENV
A prior test has changed APP_ENV!
 [ ] Tests another thing that depends on APP_ENV
 ```

Above, we can now see that the `Tests another thing` test case is leaking a change to `APP_ENV` and is likely
causing the last two tests to fail.
