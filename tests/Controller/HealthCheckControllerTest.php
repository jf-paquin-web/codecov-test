<?php

namespace App\Tests\Controller;

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
}
