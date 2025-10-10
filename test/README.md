# Test

This directory contains the Terratest suite for the `aws-private-link-service` component.

## Prerequisites

- Go 1.23 or later
- AWS credentials configured
- Atmos CLI installed

## Test Structure

The test suite includes:

### Basic Test (`TestBasic`)
- Creates a VPC
- Creates a test Network Load Balancer (NLB)
- Creates a VPC Endpoint Service attached to the NLB
- Validates all outputs:
  - VPC Endpoint Service ID
  - VPC Endpoint Service ARN
  - VPC Endpoint Service Name (service name consumers use to connect)
  - VPC Endpoint Service State
  - SNS Topic ARN for endpoint connection events
- Runs drift detection

### Enabled Flag Test (`TestEnabledFlag`)
- Verifies that the component can be disabled with `enabled: false`
- Ensures no resources are created when disabled

## Running Tests

```bash
# Run all tests
atmos test run

# Run from the test directory
cd test
go test -v -timeout 60m
```

## Test Dependencies

The tests automatically create and destroy these dependencies:
- VPC (`vpc`) - Provides networking infrastructure
- Test NLB (`test-nlb`) - A minimal Network Load Balancer for testing

## Test Fixtures

Test fixtures are located in `fixtures/stacks/`:
- `catalog/usecase/basic.yaml` - Basic test configuration
- `catalog/usecase/disabled.yaml` - Disabled component test configuration
- `catalog/test-nlb.yaml` - Test NLB configuration
- `catalog/vpc.yaml` - VPC configuration

## Cleanup

Tests automatically clean up all resources after completion. If a test fails mid-run, you may need to manually clean up resources.
