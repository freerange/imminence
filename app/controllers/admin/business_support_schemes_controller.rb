class Admin::BusinessSupportSchemesController < InheritedResources::Base 
  include Admin::AdminControllerMixin
 
  actions :all, :only => [:index, :edit, :update]

  before_filter :find_all_facets, :only => [:new, :edit]

  def index
    @schemes = BusinessSupportScheme.asc(:title)
  end

  def new
    @scheme = BusinessSupportScheme.new(
      business_support_identifier: BusinessSupportScheme.next_identifier)
  end

  def create
    @scheme = BusinessSupportScheme.new(params[:business_support_scheme])
    if @scheme.save
      redirect_to admin_business_support_schemes_path, 
        :notice => "#{@scheme.title} successfully created"
    else
      find_all_facets
      render :action => 'new'
    end
  end

  def edit
    @scheme = BusinessSupportScheme.find(params[:id])
  end

  def update
    @scheme = BusinessSupportScheme.find(params[:id])
    if @scheme.update_attributes(params[:business_support_scheme])
      redirect_to admin_business_support_schemes_path,
        :notice => "#{@scheme.title} successfully updated"
    else
      find_all_facets
      render :action => 'edit'
    end
  end

  def find_all_facets
    @business_types = BusinessSupportBusinessType.asc(:name)
    @locations = BusinessSupportLocation.asc(:name)
    @sectors = BusinessSupportSector.asc(:name)
    @stages = BusinessSupportStage.asc(:name)
    @types = BusinessSupportType.asc(:name)
  end

end
