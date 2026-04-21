<?php

namespace LibreNMS\Alert\Transport;

use LibreNMS\Alert\Transport;
use LibreNMS\Exceptions\AlertTransportDeliveryException;
use LibreNMS\Util\Http;

class Xmatters extends Transport
{
    protected string $name = 'xMatters';

    public function deliverAlert(array $alert_data): bool
    {
        $url = $this->config['xmatters_url'];

        $device_url = \Config::get('base_url');
        $device_groups = \DeviceCache::get($alert_data['device_id'])
            ->groups
            ->pluck('name');

        $data = [
            'properties' => $alert_data,
            'recipients' => $alert_data['contacts'],
            'priority' => $this->mapSeverityToPriority($alert_data['severity'])
        ];

        $data['properties']['event_state'] = $this->mapStateToEventState($alert_data['state']);
        $data['properties']['instance_url'] = $device_url;
        $data['properties']['hostname'] = $alert_data['sysName'];
        $data['properties']['ip'] = $alert_data['hostname'];
        $data['properties']['device_url'] = $device_url . '/device/' . $alert_data['device_id'];
        $data['properties']['alert_url'] = $device_url . '/device/' . $alert_data['device_id'] . '/alerts/' . $alert_data['alert_id'];
        $data['properties']['device_groups'] = array_values($alert_data['device_groups'] ?? $device_groups->all());

        // ---- RETRY CONFIG ----
        $max_attempts = 3;
        $base_delay_ms = 200;   // base backoff
        $max_delay_ms  = 2000;  // cap backoff
        $status = 0;
        $response_body = 'no response';

        for ($attempt = 1; $attempt <= $max_attempts; $attempt++) {

            // ---- PRE-SEND JITTER ----
            usleep(random_int(0, 250000)); // 0-250ms jitter

            try {
                $res = Http::client()
                    ->withBasicAuth(
                        $this->config['xmatters_api_key'],
                        $this->config['xmatters_api_secret']
                    )
                    ->acceptJson()
                    ->timeout(10)
                    ->connectTimeout(5)
                    ->post($url, $data);

                if ($res->successful()) {
                    return true;
                }

                // treat non-2xx as retryable
                $status = $res->status();
                $response_body = $res->body();

            } catch (\Throwable $e) {
                $status = 0; // network-level failure
                $response_body = $e->getMessage();
            }

            // ---- FINAL ATTEMPT FAILURE ----
            if ($attempt === $max_attempts) {
                throw new AlertTransportDeliveryException(
                    $alert_data,
                    $status,
                    $response_body,
                    'xMatters delivery failed after retries',
                    $data
                );
            }

            // ---- EXPONENTIAL BACKOFF + JITTER ----
            $delay = min(
                $max_delay_ms,
                $base_delay_ms * (2 ** ($attempt - 1))
            );

            $jitter = random_int(0, 150); // small jitter per retry
            usleep(($delay + $jitter) * 1000);
        }

        return false;
    }

    protected function mapSeverityToPriority(string $severity): string {
        switch ($severity) {
            case 'critical': return 'High';
            case 'warning':  return 'Medium';
            case 'ok':       return 'Low';
            default:         return 'Low';
        }
    }

    protected function mapStateToEventState(int $state): string {
        switch ($state) {
            case 0: return 'ok';
            case 1: return 'alert';
            case 2: return 'ack';
            case 3: return 'worse';
            case 4: return 'better';
            case 5: return 'changed';
            default: return 'alert';
        }
    }

    public static function configTemplate(): array
    {
        return [
            'config' => [
                [
                    'title' => 'xMatters Trigger URL',
                    'name' => 'xmatters_url',
                    'descr' => 'The full xMatters trigger URL (for example: https://company.xmatters.com/api/integration/1/functions/<id>/triggers).',
                    'type' => 'text'
                ],
                [
                    'title' => 'xMatters API Key',
                    'name' => 'xmatters_api_key',
                    'descr' => 'The API Key key for authenticating the flow http trigger or legacy inbound integration.',
                    'type' => 'text'
                ],
                [
                    'title' => 'xMatters API Secret',
                    'name' => 'xmatters_api_secret',
                    'descr' => 'The Secret matching the API Key for authenticating the flow http trigger or legacy inbound integration.',
                    'type' => 'password'
                ]
            ],
            'validation' => [
                'xmatters_url' => 'required|url',
                'xmatters_api_key' => 'required|string',
                'xmatters_api_secret' => 'required|string'
            ]
        ];
    }
}
