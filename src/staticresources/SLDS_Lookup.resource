(function(w, j$)
{
	angular.module('lookup', []).controller('objectSearch', 
		['$q', 'searchForRecords', function($q, searchForRecords)
	{
		var vm = this;
		vm.recordName = '',
			vm.foundRecords = [],
			vm.selectedRecords = [],
			vm.errors = '',
			vm.noResultsMessage = '',
			vm.whereClause = '',
			vm.disableInput = false,
			vm.sObjectType = '';

		
		j$(document).ready(function(){
			vm.whereClause = j$('input[id$="whereClause"]').val();
			vm.sObjectType = j$('input[id$="sObjectType"]').val();
		});

		vm.search = function(){

			if (vm.recordName == ''){
				vm.foundRecords = [];
				return;
			}

			vm.disableInput = true;

			searchForRecords(vm.sObjectType, vm.recordName, vm.whereClause).then(
				function(result)
				{
					vm.disableInput = false;
					vm.foundRecords = result;
					if ( result.length == 0 ){
						vm.noResultsMessage = 'No results were found';
					}
				},
				function(result)
				{
					vm.disableInput = false;
					vm.errors = result.message;
				}
			);
		},

		vm.closeDropdown = function(){
			vm.foundRecords = [];
			vm.noResultsMessage = '';
		},

		vm.closeErrorBox = function()
		{
			vm.errors = '';
		},

		vm.selectRecord = function( index )
		{
			var selectedRecord = vm.foundRecords[index];
			vm.recordName = selectedRecord.Name;
			vm.closeDropdown();
			console.log( selectedRecord.Name );
			console.log( selectedRecord.Id );
			assignToController( selectedRecord.Name, selectedRecord.Id );
		},

		vm.redirectToDetailPage = function(){
			window.location = '/agents/ac_opportunity_detail?Id=' + vm.opportunityId + '&tab=related';
		};
	}]);

}(window, jQuery));