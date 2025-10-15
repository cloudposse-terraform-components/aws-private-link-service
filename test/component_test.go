package test

import (
	"testing"

	"github.com/cloudposse/test-helpers/pkg/atmos"
	helper "github.com/cloudposse/test-helpers/pkg/atmos/component-helper"
	"github.com/stretchr/testify/assert"
)

type ComponentSuite struct {
	helper.TestSuite
}

func (s *ComponentSuite) TestBasic() {
	const component = "private-link-service/basic"
	const stack = "default-test"

	defer s.DestroyAtmosComponent(s.T(), component, stack, nil)
	options, _ := s.DeployAtmosComponent(s.T(), component, stack, nil)
	assert.NotNil(s.T(), options)

	// Verify VPC Endpoint Service outputs
	vpcEndpointServiceID := atmos.Output(s.T(), options, "vpc_endpoint_service_id")
	assert.NotEmpty(s.T(), vpcEndpointServiceID)

	vpcEndpointServiceARN := atmos.Output(s.T(), options, "vpc_endpoint_service_arn")
	assert.NotEmpty(s.T(), vpcEndpointServiceARN)
	assert.Contains(s.T(), vpcEndpointServiceARN, "vpc-endpoint-service")

	vpcEndpointServiceName := atmos.Output(s.T(), options, "vpc_endpoint_service_name")
	assert.NotEmpty(s.T(), vpcEndpointServiceName)
	assert.Contains(s.T(), vpcEndpointServiceName, "com.amazonaws.vpce")

	vpcEndpointServiceState := atmos.Output(s.T(), options, "vpc_endpoint_service_state")
	assert.NotEmpty(s.T(), vpcEndpointServiceState)
	assert.Contains(s.T(), []string{"Available", "Pending"}, vpcEndpointServiceState)

	endpointEventsSNSTopicARN := atmos.Output(s.T(), options, "endpoint_events_sns_topic_arn")
	assert.NotEmpty(s.T(), endpointEventsSNSTopicARN)
	assert.Contains(s.T(), endpointEventsSNSTopicARN, "sns")

	s.DriftTest(component, stack, nil)
}

func (s *ComponentSuite) TestEnabledFlag() {
	const component = "private-link-service/disabled"
	const stack = "default-test"
	s.VerifyEnabledFlag(component, stack, nil)
}

func (s *ComponentSuite) SetupSuite() {
	s.TestSuite.InitConfig()
	s.TestSuite.Config.ComponentDestDir = "components/terraform/private-link-service"
	s.TestSuite.SetupSuite()
}

func TestRunSuite(t *testing.T) {
	suite := new(ComponentSuite)
	suite.AddDependency(t, "vpc", "default-test", nil)
	suite.AddDependency(t, "nlb", "default-test", nil)
	helper.Run(t, suite)
}
