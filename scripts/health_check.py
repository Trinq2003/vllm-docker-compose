#!/usr/bin/env python3
"""
Deployment Repository - Health Check Script

This script performs comprehensive health checks on all deployed services
including connectivity, performance, and resource utilization checks.

Usage:
    python scripts/health_check.py [--verbose] [--json] [--alert]

Options:
    --verbose, -v    Show detailed output
    --json, -j       Output results in JSON format
    --alert, -a      Send alerts for failed services
"""

import argparse
import asyncio
import json
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import Dict, List, Optional, Any
import logging

import requests
import aiohttp
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class ServiceCheck:
    """Represents the result of a service health check."""
    name: str
    url: str
    status: str  # 'healthy', 'unhealthy', 'unknown'
    response_time: Optional[float] = None
    error_message: Optional[str] = None
    timestamp: str = ""
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()
        if self.metadata is None:
            self.metadata = {}

@dataclass
class HealthReport:
    """Comprehensive health report for all services."""
    timestamp: str
    overall_status: str  # 'healthy', 'degraded', 'unhealthy'
    total_services: int
    healthy_services: int
    unhealthy_services: int
    unknown_services: int
    checks: List[ServiceCheck]
    duration: float

class HealthChecker:
    """Main health checker class for all services."""

    def __init__(self, timeout: int = 10, max_retries: int = 3):
        self.timeout = timeout
        self.max_retries = max_retries
        self.session = self._create_session()

    def _create_session(self) -> requests.Session:
        """Create a requests session with retry strategy."""
        session = requests.Session()
        retry_strategy = Retry(
            total=self.max_retries,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        return session

    def get_services_to_check(self) -> List[Dict[str, str]]:
        """Get list of services to check with their endpoints."""
        return [
            {
                "name": "LiteLLM Proxy",
                "url": "http://localhost:4000/health/liveliness",
                "type": "api"
            },
            {
                "name": "vLLM Qwen2.5-14B",
                "url": "http://localhost:9998/health",
                "type": "model"
            },
            {
                "name": "vLLM Qwen3-30B",
                "url": "http://localhost:9999/health",
                "type": "model"
            },
            {
                "name": "Xinference",
                "url": "http://localhost:9900/health",
                "type": "model"
            },
            {
                "name": "RAGFlow",
                "url": "http://localhost:9380/",
                "type": "web"
            },
            {
                "name": "Prometheus",
                "url": "http://localhost:9090/-/healthy",
                "type": "monitoring"
            },
            {
                "name": "PostgreSQL",
                "url": "http://localhost:5432/health",  # Custom health endpoint
                "type": "database"
            },
            {
                "name": "MySQL",
                "url": "http://localhost:3306/health",  # Custom health endpoint
                "type": "database"
            },
            {
                "name": "Redis",
                "url": "http://localhost:6379/health",  # Custom health endpoint
                "type": "cache"
            },
            {
                "name": "Elasticsearch",
                "url": "http://localhost:1200/_cluster/health",
                "type": "search"
            },
            {
                "name": "MinIO",
                "url": "http://localhost:9000/minio/health/live",
                "type": "storage"
            }
        ]

    async def check_service_async(self, service: Dict[str, str]) -> ServiceCheck:
        """Asynchronously check a single service."""
        name = service["name"]
        url = service["url"]
        service_type = service["type"]

        start_time = time.time()

        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=self.timeout)) as session:
                async with session.get(url) as response:
                    response_time = time.time() - start_time

                    if response.status == 200:
                        status = "healthy"
                        error_message = None

                        # Additional checks based on service type
                        if service_type == "api" and "health" in url:
                            try:
                                data = await response.json()
                                status = data.get("status", "healthy")
                            except:
                                pass  # Keep as healthy if JSON parsing fails

                        elif service_type == "model":
                            # Check if model is actually responding
                            try:
                                text = await response.text()
                                if "healthy" not in text.lower() and "ok" not in text.lower():
                                    status = "degraded"
                            except:
                                pass

                    else:
                        status = "unhealthy"
                        error_message = f"HTTP {response.status}"

        except asyncio.TimeoutError:
            response_time = time.time() - start_time
            status = "unhealthy"
            error_message = "Timeout"

        except Exception as e:
            response_time = time.time() - start_time
            status = "unhealthy"
            error_message = str(e)

        return ServiceCheck(
            name=name,
            url=url,
            status=status,
            response_time=round(response_time * 1000, 2) if response_time else None,  # Convert to ms
            error_message=error_message,
            metadata={"type": service_type}
        )

    def check_service_sync(self, service: Dict[str, str]) -> ServiceCheck:
        """Synchronously check a single service (fallback method)."""
        name = service["name"]
        url = service["url"]
        service_type = service["type"]

        start_time = time.time()

        try:
            response = self.session.get(url, timeout=self.timeout)
            response_time = time.time() - start_time

            if response.status_code == 200:
                status = "healthy"
                error_message = None

                # Additional checks based on service type
                if service_type == "api" and "health" in url:
                    try:
                        data = response.json()
                        status = data.get("status", "healthy")
                    except:
                        pass

                elif service_type == "model":
                    if "healthy" not in response.text.lower() and "ok" not in response.text.lower():
                        status = "degraded"

            else:
                status = "unhealthy"
                error_message = f"HTTP {response.status_code}"

        except requests.exceptions.Timeout:
            response_time = time.time() - start_time
            status = "unhealthy"
            error_message = "Timeout"

        except Exception as e:
            response_time = time.time() - start_time
            status = "unhealthy"
            error_message = str(e)

        return ServiceCheck(
            name=name,
            url=url,
            status=status,
            response_time=round(response_time * 1000, 2) if response_time else None,
            error_message=error_message,
            metadata={"type": service_type}
        )

    async def run_health_checks_async(self, services: List[Dict[str, str]]) -> List[ServiceCheck]:
        """Run health checks asynchronously for all services."""
        tasks = [self.check_service_async(service) for service in services]
        return await asyncio.gather(*tasks)

    def run_health_checks_sync(self, services: List[Dict[str, str]]) -> List[ServiceCheck]:
        """Run health checks synchronously for all services (fallback)."""
        results = []
        for service in services:
            result = self.check_service_sync(service)
            results.append(result)
            logger.info(f"Checked {result.name}: {result.status}")
        return results

    def generate_report(self, checks: List[ServiceCheck], duration: float) -> HealthReport:
        """Generate a comprehensive health report."""
        healthy_count = sum(1 for check in checks if check.status == "healthy")
        unhealthy_count = sum(1 for check in checks if check.status == "unhealthy")
        unknown_count = sum(1 for check in checks if check.status == "unknown")

        # Determine overall status
        if unhealthy_count > 0:
            overall_status = "unhealthy"
        elif unknown_count > 0:
            overall_status = "degraded"
        else:
            overall_status = "healthy"

        return HealthReport(
            timestamp=datetime.now().isoformat(),
            overall_status=overall_status,
            total_services=len(checks),
            healthy_services=healthy_count,
            unhealthy_services=unhealthy_count,
            unknown_services=unknown_count,
            checks=checks,
            duration=round(duration, 2)
        )

    def print_report(self, report: HealthReport, verbose: bool = False, json_output: bool = False):
        """Print the health report in a readable format."""
        if json_output:
            print(json.dumps(asdict(report), indent=2, default=str))
            return

        print(f"\n{'='*60}")
        print("🏥 MULTI-MODEL LLM DEPLOYMENT HEALTH REPORT")
        print(f"{'='*60}")
        print(f"📅 Timestamp: {report.timestamp}")
        print(f"⏱️  Duration: {report.duration}s")
        print(f"📊 Overall Status: {self._colorize_status(report.overall_status)}")
        print(f"🔢 Total Services: {report.total_services}")
        print(f"✅ Healthy: {report.healthy_services}")
        print(f"❌ Unhealthy: {report.unhealthy_services}")
        print(f"❓ Unknown: {report.unknown_services}")
        print(f"{'='*60}")

        if verbose:
            print("\n📋 DETAILED SERVICE STATUS:")
            print("-" * 80)

            for check in report.checks:
                status_icon = self._get_status_icon(check.status)
                response_time = f"{check.response_time}ms" if check.response_time else "N/A"

                print(f"{status_icon} {check.name:<20} | {self._colorize_status(check.status):<10} | {response_time:<8} | {check.url}")

                if check.error_message and verbose:
                    print(f"{'':<24} └─ Error: {check.error_message}")

        print(f"\n{'='*60}")

        # Summary message
        if report.overall_status == "healthy":
            print("🎉 All systems operational!")
        elif report.overall_status == "degraded":
            print("⚠️  Some services have unknown status. Manual check recommended.")
        else:
            print("🚨 Critical services are down. Immediate attention required!")

    def _colorize_status(self, status: str) -> str:
        """Add color coding to status text."""
        if status == "healthy":
            return f"\033[92m{status.upper()}\033[0m"  # Green
        elif status == "unhealthy":
            return f"\033[91m{status.upper()}\033[0m"  # Red
        elif status == "degraded":
            return f"\033[93m{status.upper()}\033[0m"  # Yellow
        else:
            return f"\033[90m{status.upper()}\033[0m"  # Gray

    def _get_status_icon(self, status: str) -> str:
        """Get appropriate icon for status."""
        if status == "healthy":
            return "✅"
        elif status == "unhealthy":
            return "❌"
        elif status == "degraded":
            return "⚠️"
        else:
            return "❓"

async def main():
    """Main function to run health checks."""
    parser = argparse.ArgumentParser(description="Deployment Repository Health Checker")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show detailed output")
    parser.add_argument("-j", "--json", action="store_true", help="Output results in JSON format")
    parser.add_argument("-a", "--alert", action="store_true", help="Send alerts for failed services")
    parser.add_argument("-t", "--timeout", type=int, default=10, help="Timeout for each service check (seconds)")
    parser.add_argument("-r", "--retries", type=int, default=3, help="Max retries for each service check")

    args = parser.parse_args()

    # Initialize health checker
    checker = HealthChecker(timeout=args.timeout, max_retries=args.retries)

    # Get services to check
    services = checker.get_services_to_check()

    print("🔍 Starting health checks..." if not args.json else "", end="")
    if not args.json:
        print(f" Checking {len(services)} services...")

    start_time = time.time()

    try:
        # Try async first, fallback to sync
        checks = await checker.run_health_checks_async(services)
    except ImportError:
        # Fallback to synchronous checks if aiohttp is not available
        logger.warning("aiohttp not available, using synchronous checks")
        checks = checker.run_health_checks_sync(services)

    duration = time.time() - start_time

    # Generate and print report
    report = checker.generate_report(checks, duration)
    checker.print_report(report, verbose=args.verbose, json_output=args.json)

    # Handle alerts
    if args.alert and report.unhealthy_services > 0:
        print("\n🚨 ALERT: Some services are unhealthy!")        # Here you could integrate with alerting systems like Slack, email, etc.
        # For now, just print the information
        unhealthy_services = [check for check in checks if check.status == "unhealthy"]
        for service in unhealthy_services:
            print(f"  - {service.name}: {service.error_message}")

    # Exit with appropriate code
    if report.overall_status == "unhealthy":
        sys.exit(1)
    elif report.overall_status == "degraded":
        sys.exit(2)
    else:
        sys.exit(0)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 Health check interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        sys.exit(1)
