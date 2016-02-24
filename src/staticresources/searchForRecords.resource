(function()
{
	'use strict';
	angular
		.module('lookup')
		.factory('searchForRecords', ['$rootScope','$q', function($rootScope, $q){
			return function( sObjectType, criteria, whereClause ){
				var deferred = $q.defer();
				
				console.log('searchForRecords');

				SLDSLookupController.searchForRecords( sObjectType, criteria, whereClause, function(results, event)
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