(function()
{
	'use strict';
	angular
		.module('opportunityTeamEdit')
		.factory('loadOpportunityTeamData', ['$rootScope','$q', function($rootScope, $q){
			return function( opportunityId ){
				var deferred = $q.defer();
				
				ACOpportunityTeamMemberEditController.loadData( opportunityId, function(results, event)
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