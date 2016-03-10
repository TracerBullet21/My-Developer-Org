(function(w,$)
{
	angular.module('opportunityTeamEdit', []).controller('userSearch', 
		['$scope', 'searchForSFDCUsers', 'createOpportunityTeams', 'loadOpportunityTeamData', '$q', 
			function($scope, searchForSFDCUsers, createOpportunityTeams, loadOpportunityTeamData, $q)
	{
		var vm = this;
		vm.userName = '',
			vm.foundUsers = [],
			vm.selectedUsers = [],
			vm.hideSearchBox = false,
			vm.errors = '',
			vm.roles = [],
			vm.noResultsMessage = '';
	
		$(document).ready( function()
		{
			vm.opportunityId = $("input[id$='opportunityId']").val();
			vm.loadData();
		});

		vm.loadData = function()
		{
			loadOpportunityTeamData(vm.opportunityId).then(
				function(result){
					console.log(result);
					vm.selectedUsers = result.existingOppportunityTeamMembers;
					vm.roles = result.teamMemberRoles;
				},
				function(result){
					console.log(result);
					vm.errors = result.message;
				}
			);
		},

		vm.search = function(){
			if (vm.userName == ''){
				vm.foundUsers = [];
				return;
			}
			var foundUserIds = [];
			for (var i=0; i<vm.selectedUsers.length; i++)
			{
				foundUserIds.push(vm.selectedUsers[i].User.Id);
			}
			console.log(foundUserIds);
			searchForSFDCUsers(vm.userName, JSON.stringify(foundUserIds)).then(
				function(result)
				{
					vm.foundUsers = result;
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

		vm.addToSelectedUsers = function(index){
			var teamMember = vm.foundUsers.splice(index,1)[0];
			teamMember.User = {};
			teamMember.User.Id = teamMember.Id;
			teamMember.User.Name = teamMember.Name;
			vm.selectedUsers.push(teamMember);
			console.log(vm.selectedUsers);
		},

		vm.closeDropdown = function(){
			vm.foundUsers = [];
			vm.noResultsMessage = '';
		},

		vm.createOppTeamMembers = function(){
			var teamMembersToCreate = [];
			for ( var i=0; i<vm.selectedUsers.length; i++ )
			{
				console.log( vm.selectedUsers );
				var tempTeamMember = {},
					user = vm.selectedUsers[i];
				tempTeamMember.OpportunityId = vm.opportunityId;
				tempTeamMember.UserId = user.User.Id;
				tempTeamMember.TeamMemberRole = user.TeamMemberRole;
				tempTeamMember.OpportunityAccessLevel = user.OpportunityAccessLevel;
				tempTeamMember.isPrimary = user.isPrimary;
				teamMembersToCreate.push(tempTeamMember);
			}
			console.log( teamMembersToCreate );
			createOpportunityTeams( JSON.stringify(teamMembersToCreate)).then(
				function(result){
					vm.redirectToDetailPage();
				},
				function (result){
					console.log(result);
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


	}]);

}(window, jQuery));