window.StaffPlan =
  Models: {}
  Collections: {}
  Templates: {}
  Mixins:
    Events: {}
  Views:
    Shared: {}
    StaffPlans:
      Client: {}
      WorkWeeks: {}
      Assignments: {}
    Assignments: {}
    Users: {}
    Projects:
      WorkWeeks: {}
    Clients: {}
  Routers: {}
  Dispatcher: _.extend {}, Backbone.Events
  initialize: (data) ->
    @users = new StaffPlan.Collections.Users data.users
    @projects = new StaffPlan.Collections.Projects data.projects
    @clients = new StaffPlan.Collections.Clients data.clients
    @assignments = new StaffPlan.Collections.Assignments data.assignments
    @currentCompany = data.currentCompany
    @currentUser = data.currentUser
    @relevantYears = _.uniq(_.flatten(StaffPlan.assignments.reduce (memo, assignment) ->
                        memo.push _.uniq(assignment.work_weeks.map (week) -> moment(week.get("beginning_of_week")).year())
                        memo
                      , []))
    year = parseInt(localStorage.getItem("yearFilter"), 10)
    if _.include(@relevantYears, year)
      StaffPlan.assignments.each (assignment) ->
        assignment.set "filteredWeeks", assignment.work_weeks.select (week) ->
          moment(week.get("beginning_of_week")).year() is year

    new StaffPlan.Routers.StaffPlan
      users: @users
      projects: @projects
      clients: @clients
      currentCompany: @currentCompany
      currentUser: @currentUser
    $ -> Backbone.history.start(pushState: true)
    
    $('a:not([data-bypass])').live 'click', (event) =>
      event.preventDefault()
      href = $(event.currentTarget).attr('href').slice(1)
      Backbone.history.navigate(href, true)
      
    $('body header select.year-filter').val(localStorage.getItem("yearFilter")).live 'change', (event) ->
      year = $(event.target).val()
      localStorage.setItem("yearFilter", $(event.target).val())
      StaffPlan.Dispatcher.trigger "year:changed",
        year: year
  
    
  addClientByName: (name, callback) ->
    @clients.create
      name: name
    ,
      success: callback
      
  addProjectByNameAndClient: (name, client, callback) ->
    @projects.create
      name: name
      client_id: client.get('id')
    ,
      success: callback
  
  typeAhead: (query, callback) ->
    list = StaffPlan.clients.reduce (array, client) ->
      array.push client.get('name')
      array.push _.map StaffPlan.projects.where(client_id: client.get('id')), (project) ->
        "#{project.get('name')} {#{client.get('name')}}"
      _.flatten array
    , []
    
    list.push StaffPlan.users.pluck('full_name')
    _.flatten list
  
  clearTypeAhead: ->
    $('.quick-jump').find('input').val('')
    
  onTypeAhead: ($form) ->
    typeAheadValue = $form.find('input').val().trim()
    
    if (match = typeAheadValue.match(/\{(.*)\}/i))?
      clientName = match.pop()
      client = _.detect @clients.models, (client) ->
        client.get('name') == clientName 
    
    if client?
      projectName = typeAheadValue.substr(0, typeAheadValue.indexOf('{')).trim()
      project = StaffPlan.projects.where(
        client_id: client.get('id')
        name: name
      )[0]
      @clearTypeAhead()
      url = "/projects/#{project.get('id')}"
      
    else if (client = StaffPlan.clients.detect (client) -> client.get('name') == typeAheadValue)?
      @clearTypeAhead()
      url = "/clients/#{client.get('id')}"
      
    else if (user = StaffPlan.users.detect (user) -> user.get('full_name') == typeAheadValue)?
      @clearTypeAhead()
      url = "/staffplans/#{user.get('id')}"
    
    Backbone.history.navigate(url, true) if url?