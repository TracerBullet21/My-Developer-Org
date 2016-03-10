(function(w,$)
{
	angular.module('partnerRole', []).controller('AccountSearch', 
		['$scope', 'searchForSFDCAccounts', 'createPartnerRoles', 'loadData', '$q', function($scope, searchForSFDCAccounts, createPartnerRoles, loadData, $q)
	{

		//Model for Partners = partner.Partner__c, partner.Partner__r.Name, partner.Project__c, partner.Role__c, partner.Primary__c 

		var vm = this;
		vm.accountName = '',
			vm.foundAccounts = [],
			vm.selectedAccounts = [],
			vm.hideSearchBox = false,
			vm.errors = '',
			vm.partnerRoles = [],
			vm.noResultsMessage = '';
	
		$(document).ready( function()
		{
			vm.opportunityId = j$("input[id$='opportunityId']").val();
			vm.loadData();
		});

		vm.loadData = function()
		{
			console.log('Loading Data');
			loadData(vm.opportunityId).then(
				function(result){
					console.log(result);
					vm.partnerRoles = result.partnerRoles;
					vm.selectedAccounts = result.existingPartners;
				},
				function(result){
					console.log(result);
					vm.errors = result.message;
				}
			);
		},

		vm.search = function(){
			console.log('starting search');
			if (vm.accountName == ''){
				vm.foundAccounts = [];
				return;
			}
			console.log('Account Name: ' + vm.accountName);
			searchForSFDCAccounts(vm.accountName, vm.opportunityId).then(
				function(result)
				{
					vm.foundAccounts = result;
					if ( result.length == 0 ){
						vm.noResultsMessage = 'No results were found';
					}
				},
				function(result)
				{
					vm.errors = result.message;
				}
			);
		},

		vm.addToSelectedAccounts = function(index){
			var account = vm.foundAccounts.splice(index,1);
			vm.selectedAccounts.push(convertAccountToPartner(account[0]));
			console.log(vm.selectedAccounts);
		},

		vm.closeDropdown = function(){
			vm.foundAccounts = [];
			vm.noResultsMessage = '';
		},

		vm.createPartners = function(){
			createPartnerRoles( JSON.stringify(vm.selectedAccounts)).then(
				function(result){
					vm.redirectToDetailPage();
				},
				function (result){
					vm.errors = result.message;
				}
			);
		},

		vm.closeErrorBox = function()
		{
			vm.errors = '';
		},

		vm.redirectToDetailPage = function(){
			window.location = '/agents/ac_opportunity_detail?Id=' + vm.opportunityId + '&tab=related';
		};

		w.convertAccountToPartner = function( account ){
			var partner = {};
			partner.Partner__c = account.Id;
			partner.Partner__r = account;
			partner.Project__c = vm.opportunityId;
			partner.Role__c = '';
			partner.Primary__c = false;
			return partner;
		};

	}]);

}(window, jQuery));