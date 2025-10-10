package test

import (
	"fmt"
	"testing"
	"strings"
	helper "github.com/cloudposse/test-helpers/pkg/atmos/component-helper"
	"github.com/cloudposse/test-helpers/pkg/atmos"
	"github.com/cloudposse/test-helpers/pkg/helm"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/modules/random"
)

type ComponentSuite struct {
	helper.TestSuite
}

func (s *ComponentSuite) TestBasic() {
	const component = "eks/echo-server/basic"
	const stack = "default-test"
	const awsRegion = "us-east-2"

	randomID := strings.ToLower(random.UniqueId())

	dnsDelegatedOptions := s.GetAtmosOptions("dns-delegated", stack, nil)
	delegatedDomainName := atmos.Output(s.T(), dnsDelegatedOptions, "default_domain_name")

	domainTemplate := fmt.Sprintf("echo-%s.%s.%s", randomID, "%[3]v.%[2]v.%[1]v", delegatedDomainName)

	namespace := fmt.Sprintf("echo-%s", randomID)

	inputs := map[string]interface{}{
		"kubernetes_namespace": namespace,
		"hostname_template": domainTemplate,
	}

	defer s.DestroyAtmosComponent(s.T(), component, stack, &inputs)
	options, _ := s.DeployAtmosComponent(s.T(), component, stack, &inputs)
	assert.NotNil(s.T(), options)

	metadata := helm.Metadata{}

	atmos.OutputStruct(s.T(), options, "metadata", &metadata)

	assert.Equal(s.T(), metadata.AppVersion, "0.8.0")
	assert.Equal(s.T(), metadata.Chart, "echo-server")
	assert.NotNil(s.T(), metadata.FirstDeployed)
	assert.NotNil(s.T(), metadata.LastDeployed)
	assert.Equal(s.T(), metadata.Name, "echo-server")
	assert.Equal(s.T(), metadata.Namespace, namespace)
	assert.NotNil(s.T(), metadata.Values)
	assert.Equal(s.T(), metadata.Version, "0.4.0")

	hostname := atmos.Output(s.T(), options, "hostname")
	assert.NotNil(s.T(), hostname)

	s.DriftTest(component, stack, &inputs)
}

func (s *ComponentSuite) TestEnabledFlag() {
	const component = "eks/echo-server/disabled"
	const stack = "default-test"
	s.VerifyEnabledFlag(component, stack, nil)
}

func (s *ComponentSuite) SetupSuite() {
	s.TestSuite.InitConfig()
	s.TestSuite.Config.ComponentDestDir = "components/terraform/eks/echo-server"
	s.TestSuite.SetupSuite()
}

func TestRunSuite(t *testing.T) {
	suite := new(ComponentSuite)
	suite.AddDependency(t, "vpc", "default-test", nil)
	suite.AddDependency(t, "eks/cluster", "default-test", nil)
	suite.AddDependency(t, "eks/alb-controller", "default-test", nil)

	subdomain := strings.ToLower(random.UniqueId())
	inputs := map[string]interface{}{
		"zone_config": []map[string]interface{}{
			{
				"subdomain": subdomain,
				"zone_name": "components.cptest.test-automation.app",
			},
		},
	}
	suite.AddDependency(t, "dns-delegated", "default-test", &inputs)
	helper.Run(t, suite)
}
