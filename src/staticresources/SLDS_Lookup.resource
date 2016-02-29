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
			vm.searching = false,
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

			vm.searching = true;

			searchForRecords(vm.sObjectType, vm.recordName, vm.whereClause).then(
				function(result)
				{
					vm.searching = false;
					vm.foundRecords = result;
					if ( result.length == 0 ){
						vm.noResultsMessage = 'No results were found';
					}
				},
				function(result)
				{
					vm.searching = false;
					vm.errors = result.message;
				}
			);
		},

		vm.closeDropdown = function(){
			vm.foundRecords = [];
			vm.noResultsMessage = '';
			vm.recordName = '';
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
			assignToController( selectedRecord.Name, selectedRecord.Id );
		};

	}]);

	angular.module('lookup').directive('ngEnter', function()
	{
	    return function (scope, element, attrs)
	    {
	        element.bind("keydown keypress", function (event) 
	        {
	            if(event.which === 13)
	            {
	                scope.$apply(function ()
	                {
	                    scope.$eval(attrs.ngEnter);
	                });
	                event.preventDefault();
	            }
	        });
	    };
	});

}(window, jQuery));