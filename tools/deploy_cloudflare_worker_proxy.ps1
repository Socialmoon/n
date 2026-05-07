$ErrorActionPreference = 'Stop'

$envMap = @{}
foreach ($line in Get-Content '.env') {
  if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
  $parts = $line -split '=', 2
  if ($parts.Length -eq 2) {
    $envMap[$parts[0].Trim()] = $parts[1].Trim()
  }
}

$token = $envMap['CLOUDFLARE_API_TOKEN']
$accountId = $envMap['CLOUDFLARE_ACCOUNT_ID']
$zoneId = $envMap['CLOUDFLARE_ZONE_ID']
$mediaHost = $envMap['CLOUDFLARE_MEDIA_HOST']
$workerName = 'apnesaathi-supabase-proxy'

if ([string]::IsNullOrWhiteSpace($token) -or [string]::IsNullOrWhiteSpace($accountId) -or [string]::IsNullOrWhiteSpace($zoneId) -or [string]::IsNullOrWhiteSpace($mediaHost)) {
  throw 'Missing one of CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_ZONE_ID, CLOUDFLARE_MEDIA_HOST in .env'
}

$headersJson = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$headersJs = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/javascript' }

$workerCode = @'
export default {
  async fetch(request, env, ctx) {
    const incomingUrl = new URL(request.url);
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    const upstreamUrl = `https://iuhecyqizatkiskoznwq.supabase.co${incomingUrl.pathname}${incomingUrl.search}`;

    const upstreamReq = new Request(upstreamUrl, {
      method: request.method,
      redirect: 'follow',
      cf: {
        cacheEverything: true,
        cacheTtl: 2592000,
        cacheKey: upstreamUrl,
      },
    });

    const upstreamRes = await fetch(upstreamReq);
    const headers = new Headers(upstreamRes.headers);

    // Keep browsers warm for 7 days and Cloudflare edge for 30 days.
    headers.delete('Set-Cookie');
    headers.set('X-Apne-Saathi-CDN', 'cloudflare-worker');
    headers.set('Cache-Control', 'public, max-age=604800, s-maxage=2592000');
    headers.set('CDN-Cache-Control', 'public, max-age=2592000');

    return new Response(upstreamRes.body, {
      status: upstreamRes.status,
      statusText: upstreamRes.statusText,
      headers,
    });
  }
};
'@

Write-Output "Deploying worker script: $workerName"
$deployUri = "https://api.cloudflare.com/client/v4/accounts/$accountId/workers/scripts/$workerName"
$deployRes = Invoke-RestMethod -Method Put -Uri $deployUri -Headers $headersJs -Body $workerCode
if (-not $deployRes.success) {
  throw "Worker deploy failed: $($deployRes | ConvertTo-Json -Depth 8)"
}

$routePattern = "$mediaHost/*"
$routesUri = "https://api.cloudflare.com/client/v4/zones/$zoneId/workers/routes"
$routesRes = Invoke-RestMethod -Method Get -Uri $routesUri -Headers $headersJson
$existing = @($routesRes.result | Where-Object { $_.pattern -eq $routePattern })

if ($existing.Count -gt 0) {
  if ($existing[0].script -ne $workerName) {
    Write-Output "Updating existing route to script $workerName"
    $updateBody = @{ pattern = $routePattern; script = $workerName } | ConvertTo-Json
    $updateUri = "$routesUri/$($existing[0].id)"
    $updateRes = Invoke-RestMethod -Method Put -Uri $updateUri -Headers $headersJson -Body $updateBody
    if (-not $updateRes.success) {
      throw "Route update failed: $($updateRes | ConvertTo-Json -Depth 8)"
    }
    Write-Output "Route updated: $routePattern"
  } else {
    Write-Output "Route already mapped: $routePattern -> $workerName"
  }
} else {
  Write-Output "Creating route: $routePattern -> $workerName"
  $routeBody = @{ pattern = $routePattern; script = $workerName } | ConvertTo-Json
  $createRouteRes = Invoke-RestMethod -Method Post -Uri $routesUri -Headers $headersJson -Body $routeBody
  if (-not $createRouteRes.success) {
    throw "Route create failed: $($createRouteRes | ConvertTo-Json -Depth 8)"
  }
  Write-Output "Route created: $routePattern"
}

Write-Output 'Worker proxy deployment complete.'
