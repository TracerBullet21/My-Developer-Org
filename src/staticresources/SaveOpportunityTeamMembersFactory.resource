(function()
{
	'use strict';
	angular
		.module('opportunityTeamEdit')
		.factory('createOpportunityTeams', ['$rootScope','$q', function($rootScope, $q){
			return function( opportunityTeamMembersJSON ){
				var deferred = $q.defer();
				
				console.log(opportunityTeamMembersJSON);
				ACOpportunityTeamMemberEditController.createOpportunityTeamMembers( opportunityTeamMembersJSON, function(results, event)
				{
		        	$rootScope.$apply( function()
		        	{
				        if(event.type === 'exception'){
				        	// handle exception
				        	deferred.reject(event);
				        }else if(event.status){
				        	//handle success
							deferred.resolve(results);
				        }else{
				        	// handle further exception
				        	deferred.reject(event);
				        }
		        	});

				}, { buffer: true, escape: false, timeout: 30000 }
				);
				return deferred.promise;
			}
		}]);
}());