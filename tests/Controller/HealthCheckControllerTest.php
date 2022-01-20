<?php

namespace App\Tests\Controller;

use App\Controller\HealthCheckController;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class HealthCheckControllerTest extends WebTestCase
{
    public function testHealthcheckReturnsSuccess(): void
    {
        $client = static::createClient();
        $client->request('GET', '/healthcheck');

        $this->assertResponseIsSuccessful();
        $this->assertResponseHeaderSame('Content-Type', 'application/json');
        $this->assertStringContainsString('success', $client->getResponse()->getContent());
    }

    public function testUncoveredCode(): void
    {
        $controller = new HealthCheckController();
        $this->assertEquals('test', $controller->uncoveredCode());
    }
}
