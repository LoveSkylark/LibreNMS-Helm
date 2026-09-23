<?php

/* Copyright (c) 2019 GitStoph <https://github.com/GitStoph>
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 */

/**
 * Jira Webhook & API Transport
 *
 * @author Skylark <https://github.com/LoveSkylark>
 * @copyright 2025 Skylark
 * @license GPL
 */

namespace LibreNMS\Alert\Transport;

use LibreNMS\Alert\Transport;
use LibreNMS\Exceptions\AlertTransportDeliveryException;
use LibreNMS\Util\Http;

class Jiranew extends Transport
{
    protected string $name = 'Jira webhook';

    public function deliverAlert(array $alert_data): bool
    {
        $webhook_on = (bool) ($this->config['enable-webhook'] ?? false);

        $state = (int) ($alert_data['state'] ?? 0);

        /*
         * Open alert
         */
        if ($state !== 0) {
            $url = (string) ($this->config['jira-url'] ?? '');
            $token = $this->config['jira-token-open'] ?? null;

            if (! $webhook_on) {
                $url = rtrim($url, '/') . '/rest/api/latest/issue';
            }
        }

        /*
         * Recovered alert
         */
        else {
            if (! $webhook_on) {
                return false;
            }

            $url = (string) ($this->config['jira-close-url'] ?? '');
            $token = $this->config['jira-token-close'] ?? null;
        }

        $project_key = (string) ($this->config['jira-key'] ?? '');
        $issue_type = (string) ($this->config['jira-type'] ?? '');

        $hostname = (string) ($alert_data['hostname'] ?? 'Unknown host');

        $title = ! empty($alert_data['title'])
            ? (string) $alert_data['title']
            : 'LibreNMS alert for: ' . $hostname;

        $description = (string) ($alert_data['msg'] ?? '');

        /*
         * Construct the Jira payload.
         */
        $data = [
            'fields' => [
                'summary' => $title,
                'description' => $description,
                'project' => [
                    'key' => $project_key,
                ],
                'issuetype' => [
                    'name' => $issue_type,
                ],
            ],
        ];

        /*
         * Add the LibreNMS alert ID for webhook processing.
         */
        if ($webhook_on) {
            $alert_id = $alert_data['id'] ?? null;

            if ($alert_id !== null) {
                $webhook_id = trim(
                    (string) ($this->config['webhook-id'] ?? '')
                );

                if ($webhook_id !== '') {
                    $data['fields'][$webhook_id] = $alert_id;
                } else {
                    $data['fields']['alert_id'] = $alert_id;
                }
            }
        }

        /*
         * Add custom Jira fields.
         */
        $custom_json = (string) ($this->config['jira-custom'] ?? '');

        if ($custom_json !== '') {
            $custom = json_decode($custom_json, true);

            if (
                json_last_error() === JSON_ERROR_NONE
                && is_array($custom)
                && ! empty($custom)
            ) {
                $data['fields'] = array_merge(
                    $data['fields'],
                    $custom
                );
            }
        }

        /*
         * Create HTTP client.
         */
        $client = Http::client();

        if ($webhook_on) {
            $client = $client->withHeaders([
                'X-Automation-Webhook-Token' => (string) ($token ?? ''),
            ]);
        } else {
            $client = $client->withBasicAuth(
                (string) ($this->config['jira-username'] ?? ''),
                (string) ($this->config['jira-password'] ?? '')
            );
        }

        /*
         * Send request.
         */
        $res = $client
            ->acceptJson()
            ->post($url, $data);

        if ($res->successful()) {
            return true;
        }

        /*
         * Delivery failed.
         */
        throw new AlertTransportDeliveryException(
            $alert_data,
            $res->status(),
            $res->body(),
            $description,
            $data
        );
    }

    public static function configTemplate(): array
    {
        return [
            'config' => [
                [
                    'title' => 'Project Key',
                    'name' => 'jira-key',
                    'descr' => 'Jira Project Key',
                    'type' => 'text',
                ],
                [
                    'title' => 'Issue Type',
                    'name' => 'jira-type',
                    'descr' => 'Jira Issue Type',
                    'type' => 'text',
                ],
                [
                    'title' => 'Ticket URL (Open)',
                    'name' => 'jira-url',
                    'descr' => 'Create Jira Ticket',
                    'type' => 'text',
                ],
                [
                    'title' => 'Jira Token (Open)',
                    'name' => 'jira-token-open',
                    'descr' => 'Secret | Webhook Only',
                    'type' => 'text',
                ],
                [
                    'title' => 'Ticket URL (Close)',
                    'name' => 'jira-close-url',
                    'descr' => 'Close Jira Ticket | Webhook Only',
                    'type' => 'text',
                ],
                [
                    'title' => 'Jira Token (Close)',
                    'name' => 'jira-token-close',
                    'descr' => 'Secret | Webhook Only',
                    'type' => 'text',
                ],
                [
                    'title' => 'Jira Username',
                    'name' => 'jira-username',
                    'descr' => 'Jira Username',
                    'type' => 'text',
                ],
                [
                    'title' => 'Jira Password',
                    'name' => 'jira-password',
                    'descr' => 'Jira Password',
                    'type' => 'password',
                ],
                [
                    'title' => 'Enable Webhook',
                    'name' => 'enable-webhook',
                    'descr' => 'Use Webhook instead of API',
                    'type' => 'checkbox',
                    'default' => false,
                ],
                [
                    'title' => 'Webhook Identifier',
                    'name' => 'webhook-id',
                    'descr' => 'Jira Webhook Identifier',
                    'type' => 'text',
                ],
                [
                    'title' => 'Custom Fields',
                    'name' => 'jira-custom',
                    'type' => 'textarea',
                    'descr' => '{&quot;components&quot;: [{&quot;id&quot;: &quot;00001&quot;}],&#xA;&quot;customfield_10001&quot;: [{&quot;id&quot;: &quot;00002&quot;}]}',
                ],
            ],

            'validation' => [
                'jira-key' => 'required|string',
                'jira-url' => 'required|url',
                'jira-close-url' => 'nullable|url',
                'webhook-id' => 'nullable|string',
                'jira-type' => 'required|string',
            ],
        ];
    }
}