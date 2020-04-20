
#
# NeuroHub Project
#
# Copyright (C) 2020
# The Royal Institution for the Advancement of Learning
# McGill University
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Helper for Neurohub interface
module NeurohubHelpers

  # For the user +user+, this method will return a proper
  # neurohub project (class WorkGroup) associated with +id_or_project+.
  # If +id_or_project_ is already a Group, it will make sure it's
  # a valid one. The WorkGroup is returned. If the validation fails,
  # an exception ActiveRecord::RecordNotFound is raised.
  def find_nh_project(user, id_or_project, check_license=true)
    id      = id_or_project.is_a?(Group) ? id_or_project.id : id_or_project
    project = user.viewable_groups
                  .where(:type => 'WorkGroup')
                  .where(:invisible => false)
                  .find(id)

    raise ActiveRecord::RecordNotFound unless project.can_be_accessed_by?(user)

    if check_license && user.unsigned_custom_licenses(project).present?
      raise CbrainLicenseException
    end

    project
  end

  # For the user +user+, this method will return
  # neurohub projects ('available' groups of class WorkGroup)
  def find_nh_projects(user)
    user.viewable_groups
        .where(:type      => 'WorkGroup')
        .where(:invisible => false)
  end

  # This function validates the page and per_page parameters
  # and store them in the session, if needed.
  def pagination_check(collection, modelkey)
    ppkey    = "#{modelkey}_per_page"
    page     = params[:page].presence.try(:to_i) || 1
    per_page = (params[:per_page].presence || session[ppkey].presence).try(:to_i) || 20
    per_page = 5 if per_page < 5 || per_page > 100

    # Compare page number with collection size and adjust if needed
    totsize  = collection.count # works for arrays or ActiveRecord relations
    offset   = (page-1)*per_page
    page     = ((totsize+per_page-1) / per_page) if offset >= totsize

    # Make persistent in session
    session[ppkey] = per_page

    # Same back in params, in case someone fetches the info there (e.g. pagy)
    params[:page]     = page
    params[:per_page] = per_page

    # Return a sane page number and page size
    return [ page, per_page ]
  end

  # For +user+, return the private storage (DataProvider) named
  # by +id_or_dp+ which can be an ID or a DataProvider itself.
  def find_nh_storage(user, id_or_dp)
    id = id_or_dp.is_a?(DataProvider) ? id_or_dp.id : id_or_dp
    find_all_nh_storages(user).find(id)
  end

  # Returns all private storages (DataProviders) of +user+
  def find_all_nh_storages(user)
    UserkeyFlatDirSshDataProvider.where(:user_id => user.id)
  end

end
