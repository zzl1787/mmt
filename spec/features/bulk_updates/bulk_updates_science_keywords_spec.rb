require 'rails_helper'

describe 'Bulk updating Science Keywords' do
  before :all do
    _ingest_response, @find_and_remove_concept_response = publish_collection_draft
    _ingest_response, @add_to_existing_concept_response = publish_collection_draft
    _ingest_response, @find_and_replace_concept_response = publish_collection_draft
    _ingest_response, @clear_all_and_replace_concept_response = publish_collection_draft
  end

  before do
    login

    visit new_bulk_updates_search_path
  end

  context 'when previewing a Find & Remove bulk update', js: true do
    before do
      # Search form
      select 'Entry Title', from: 'Search Field'
      fill_in 'query_text', with: @find_and_remove_concept_response.body['EntryTitle']
      click_button 'Submit'

      # Select search results
      check 'checkall'
      click_on 'Next'

      # Bulk update form
      select 'Science Keywords', from: 'Field to Update'
      select 'Find & Remove', from: 'Update Type'
      fill_in 'Level 1', with: 'MOBILE GEOGRAPHIC INFORMATION SYSTEMS'
      click_on 'Preview'
    end

    it 'displays the preview information' do
      expect(page).to have_content('Preview of New MMT_2 Bulk Update')

      expect(page).to have_content('Field to Update Science Keywords')
      expect(page).to have_content('Update Type Find And Remove')
      within '.find-values-preview' do
        expect(page).to have_content('CATEGORY: ANY VALUETOPIC: ANY VALUETERM: ANY VALUEMOBILE GEOGRAPHIC INFORMATION SYSTEMS')
      end

      within '.bulk-update-preview-table' do
        expect(page).to have_content(@find_and_remove_concept_response.body['EntryTitle'])
        expect(page).to have_content(@find_and_remove_concept_response.body['ShortName'])
      end
    end

    context 'when submitting the bulk update' do
      before do
        click_on 'Submit'

        # need to wait until the task status is 'COMPLETE'
        task_id = page.current_path.split('/').last
        wait_for_complete_bulk_update(task_id: task_id)

        # Reload the page, because CMR
        page.evaluate_script('window.location.reload()')
      end

      it 'displays the bulk update status page' do
        within '.eui-info-box' do
          expect(page).to have_content('Status Complete')
          expect(page).to have_content('Field to Update Science Keywords')
          expect(page).to have_content('Update Type Find And Remove')
        end

        within '.find-values-preview' do
          expect(page).to have_content('Find Values to Remove')
          expect(page).to have_content('MOBILE GEOGRAPHIC INFORMATION SYSTEMS')
        end

        # we can't test the time accurately, but we can check the date
        expect(page).to have_content(today_string)
      end

      context 'when viewing the collection' do
        before do
          within '#bulk-update-status-table' do
            click_on @find_and_remove_concept_response.body['EntryTitle']
          end
        end

        it 'no longer has the removed keyword' do
          within '.science-keywords-preview' do
            expect(page).to have_no_content('EARTH SCIENCE SERVICES DATA ANALYSIS AND VISUALIZATION GEOGRAPHIC INFORMATION SYSTEMS MOBILE GEOGRAPHIC INFORMATION SYSTEMS')
          end
        end
      end
    end
  end

  context 'when previewing a Add to Existing bulk update', js: true do
    before do
      # Search form
      select 'Entry Title', from: 'Search Field'
      fill_in 'query_text', with: @add_to_existing_concept_response.body['EntryTitle']
      click_button 'Submit'

      # Select search results
      check 'checkall'
      click_on 'Next'

      # Bulk update form
      select 'Science Keywords', from: 'Field to Update'
      select 'Add to Existing', from: 'Update Type'
      choose_keyword 'EARTH SCIENCE'
      choose_keyword 'ATMOSPHERE'
      choose_keyword 'AEROSOLS'
      click_on 'Select Keyword'
      click_on 'Preview'
    end

    it 'displays the preview information' do
      expect(page).to have_content('Preview of New MMT_2 Bulk Update')

      expect(page).to have_content('Field to Update Science Keywords')
      expect(page).to have_content('Update Type Add To Existing')
      within '.new-values-preview' do
        expect(page).to have_content('EARTH SCIENCEATMOSPHEREAEROSOLS')
      end

      within '.bulk-update-preview-table' do
        expect(page).to have_content(@add_to_existing_concept_response.body['EntryTitle'])
        expect(page).to have_content(@add_to_existing_concept_response.body['ShortName'])
      end
    end

    context 'when submitting the bulk update' do
      before do
        click_on 'Submit'

        # need to wait until the task status is 'COMPLETE'
        task_id = page.current_path.split('/').last
        wait_for_complete_bulk_update(task_id: task_id)

        # Reload the page, because CMR
        page.evaluate_script('window.location.reload()')
      end

      it 'displays the bulk update status page' do
        within '.eui-info-box' do
          expect(page).to have_content('Status Complete')
          expect(page).to have_content('Field to Update Science Keywords')
          expect(page).to have_content('Update Type Add To Existing')
        end

        within '.new-values-preview' do
          expect(page).to have_content('Value to Add')
          expect(page).to have_content('EARTH SCIENCEATMOSPHEREAEROSOLS')
        end

        # we can't test the time accurately, but we can check the date
        expect(page).to have_content(today_string)
      end

      context 'when viewing the collection' do
        before do
          within '#bulk-update-status-table' do
            click_on @add_to_existing_concept_response.body['EntryTitle']
          end
        end

        it 'displays the new keyword' do
          within '.science-keywords-preview' do
            expect(page).to have_content('EARTH SCIENCE ATMOSPHERE AEROSOLS')
          end
        end
      end
    end
  end

  context 'when previewing a Find & Replace bulk update', js: true do
    before do
      # Search form
      select 'Entry Title', from: 'Search Field'
      fill_in 'query_text', with: @find_and_replace_concept_response.body['EntryTitle']
      click_button 'Submit'

      # Select search results
      check 'checkall'
      click_on 'Next'

      # Bulk update form
      select 'Science Keywords', from: 'Field to Update'
      select 'Find & Replace', from: 'Update Type'
      fill_in 'Level 1', with: 'MOBILE GEOGRAPHIC INFORMATION SYSTEMS'
      # Select new keyword from picker
      choose_keyword 'EARTH SCIENCE'
      choose_keyword 'ATMOSPHERE'
      choose_keyword 'AEROSOLS'
      click_on 'Select Keyword'
      click_on 'Preview'
    end

    it 'displays the preview information' do
      expect(page).to have_content('Preview of New MMT_2 Bulk Update')

      expect(page).to have_content('Field to Update Science Keywords')
      expect(page).to have_content('Update Type Find And Replace')
      # Find Values to Replace
      within '.find-values-preview' do
        expect(page).to have_content('CATEGORY: ANY VALUETOPIC: ANY VALUETERM: ANY VALUEMOBILE GEOGRAPHIC INFORMATION SYSTEMS')
      end

      # New Values
      within '.new-values-preview' do
        expect(page).to have_content('EARTH SCIENCEATMOSPHEREAEROSOLS')
      end

      within '.bulk-update-preview-table' do
        expect(page).to have_content(@find_and_replace_concept_response.body['EntryTitle'])
        expect(page).to have_content(@find_and_replace_concept_response.body['ShortName'])
      end
    end

    context 'when submitting the bulk update' do
      before do
        click_on 'Submit'

        # need to wait until the task status is 'COMPLETE'
        task_id = page.current_path.split('/').last
        wait_for_complete_bulk_update(task_id: task_id)

        # Reload the page, because CMR
        page.evaluate_script('window.location.reload()')
      end

      it 'displays the bulk update status page' do
        within '.eui-info-box' do
          expect(page).to have_content('Status Complete')
          expect(page).to have_content('Field to Update Science Keywords')
          expect(page).to have_content('Update Type Find And Replace')
        end

        within '.find-values-preview' do
          expect(page).to have_content('Find Values to Replace')
          expect(page).to have_content('MOBILE GEOGRAPHIC INFORMATION SYSTEMS')
        end

        within '.new-values-preview' do
          expect(page).to have_content('New Value')
          expect(page).to have_content('EARTH SCIENCEATMOSPHEREAEROSOLS')
        end

        # we can't test the time accurately, but we can check the date
        expect(page).to have_content(today_string)
      end

      context 'when viewing the collection' do
        before do
          within '#bulk-update-status-table' do
            click_on @find_and_replace_concept_response.body['EntryTitle']
          end
        end

        it 'displays the new keyword' do
          within '.science-keywords-preview' do
            expect(page).to have_no_content('EARTH SCIENCE SERVICES DATA ANALYSIS AND VISUALIZATION GEOGRAPHIC INFORMATION SYSTEMS MOBILE GEOGRAPHIC INFORMATION SYSTEMS')
            expect(page).to have_content('EARTH SCIENCE ATMOSPHERE AEROSOLS')
          end
        end
      end
    end
  end

  context 'when previewing a Clear All and Replace bulk update', js: true do
    before do
      # Search form
      select 'Entry Title', from: 'Search Field'
      fill_in 'query_text', with: @clear_all_and_replace_concept_response.body['EntryTitle']
      click_button 'Submit'

      # Select search results
      check 'checkall'
      click_on 'Next'

      # Bulk update form
      select 'Science Keywords', from: 'Field to Update'
      select 'Clear All & Replace', from: 'Update Type'

      choose_keyword 'EARTH SCIENCE'
      choose_keyword 'ATMOSPHERE'
      choose_keyword 'AEROSOLS'
      click_on 'Select Keyword'
      click_on 'Preview'
    end

    it 'displays the preview information' do
      expect(page).to have_content('Preview of New MMT_2 Bulk Update')

      expect(page).to have_content('Field to Update Science Keywords')
      expect(page).to have_content('Update Type Clear All And Replace')

      # New Values
      within '.new-values-preview' do
        expect(page).to have_content('EARTH SCIENCEATMOSPHEREAEROSOLS')
      end

      within '.bulk-update-preview-table' do
        expect(page).to have_content(@clear_all_and_replace_concept_response.body['EntryTitle'])
        expect(page).to have_content(@clear_all_and_replace_concept_response.body['ShortName'])
      end
    end

    context 'when submitting the bulk update' do
      before do
        click_on 'Submit'

        # need to wait until the task status is 'COMPLETE'
        task_id = page.current_path.split('/').last
        wait_for_complete_bulk_update(task_id: task_id)

        # Reload the page, because CMR
        page.evaluate_script('window.location.reload()')
      end

      it 'displays the bulk update status page' do
        within '.eui-info-box' do
          expect(page).to have_content('Status Complete')
          expect(page).to have_content('Field to Update Science Keywords')
          expect(page).to have_content('Update Type Clear All And Replace')
        end

        within '.new-values-preview' do
          expect(page).to have_content('New Value')
          expect(page).to have_content('EARTH SCIENCEATMOSPHEREAEROSOLS')
        end
        
        # we can't test the time accurately, but we can check the date
        expect(page).to have_content(today_string)
      end

      context 'when viewing the collection' do
        before do
          within '#bulk-update-status-table' do
            click_on @clear_all_and_replace_concept_response.body['EntryTitle']
          end
        end

        it 'displays the updated keywords' do
          within '.science-keywords-preview' do
            expect(page).to have_no_content('EARTH SCIENCE SERVICES DATA ANALYSIS AND VISUALIZATION GEOGRAPHIC INFORMATION SYSTEMS MOBILE GEOGRAPHIC INFORMATION SYSTEMS')
            expect(page).to have_no_content('EARTH SCIENCE SERVICES DATA ANALYSIS AND VISUALIZATION GEOGRAPHIC INFORMATION SYSTEMS DESKTOP GEOGRAPHIC INFORMATION SYSTEMS')
            expect(page).to have_content('EARTH SCIENCE ATMOSPHERE AEROSOLS')
          end
        end
      end
    end
  end
end
