(function()
{
	'use strict';
	angular
		.module('partnerRole')
		.factory('createPartnerRoles', ['$rootScope','$q', function($rootScope, $q){
			return function( partnerRolesJSON ){
				var deferred = $q.defer();
				console.log(partnerRolesJSON);
				var clonedObject = JSON.parse(partnerRolesJSON);
				console.log(clonedObject);
				j$.each( clonedObject, function(k,v)
				{
					delete v.$$hashKey;
				});
				console.log(JSON.stringify(clonedObject));

				ACPartnerRoleEditController.createPartnerRecords( JSON.stringify(clonedObject), function(results, event)
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