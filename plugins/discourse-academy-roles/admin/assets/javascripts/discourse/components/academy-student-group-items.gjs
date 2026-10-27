import { array, concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { i18n } from "discourse-i18n";

const includes = (ids, id) => ids.includes(id);

export default <template>
  <table class="d-table academy-student-group-items">
    <caption class="sr-only">{{i18n
        "academy_roles.student_groups.result"
      }}</caption>
    <thead class="d-table__header"><tr class="d-table__row">
        <th scope="col">{{i18n "academy_roles.student_groups.select"}}</th>
        <th scope="col">{{i18n "academy_roles.student_number"}}</th>
        <th scope="col">{{i18n "academy_roles.student_invites.account"}}</th>
        <th scope="col">{{i18n
            "academy_roles.student_groups.current_groups"
          }}</th>
        <th scope="col">{{i18n "academy_roles.student_groups.add"}}</th>
        <th scope="col">{{i18n "academy_roles.student_groups.remove"}}</th>
        <th scope="col">{{i18n "academy_roles.student_invites.status"}}</th>
        <th scope="col">{{i18n "academy_roles.student_groups.reason"}}</th>
      </tr></thead>
    <tbody class="d-table__body">
      {{#each @items as |item|}}
        <tr class="d-table__row">
          <td class="d-table__cell --controls">
            {{#if @preview}}{{#if item.selectable}}
                <label><input
                    checked={{includes @selectedIds item.id}}
                    disabled={{@busy}}
                    type="checkbox"
                    {{on "change" (fn @onSelect item.id)}}
                  /><span class="sr-only">{{i18n
                      "academy_roles.student_groups.select_number"
                      number=item.student_number
                    }}</span></label>
              {{/if}}{{/if}}
          </td>
          <td class="d-table__cell --overview">{{item.student_number}}</td>
          <td class="d-table__cell --detail"><div
              class="d-table__mobile-label"
            >{{i18n "academy_roles.student_invites.account"}}</div>{{#if
              item.user_id
            }}<LinkTo
                @models={{array item.user_id item.username}}
                @route="adminUser"
              >{{item.username}}</LinkTo>{{/if}}</td>
          <td class="d-table__cell --detail"><div
              class="d-table__mobile-label"
            >{{i18n "academy_roles.student_groups.current_groups"}}</div>{{#each
              item.current_groups
              as |name|
            }}<span>{{name}} </span>{{/each}}</td>
          <td class="d-table__cell --detail"><div
              class="d-table__mobile-label"
            >{{i18n "academy_roles.student_groups.add"}}</div>{{#each
              item.add_groups
              as |name|
            }}<span>{{name}} </span>{{/each}}</td>
          <td class="d-table__cell --detail"><div
              class="d-table__mobile-label"
            >{{i18n "academy_roles.student_groups.remove"}}</div>{{#each
              item.remove_groups
              as |name|
            }}<span>{{name}} </span>{{/each}}</td>
          <td class="d-table__cell --detail"><div
              class="d-table__mobile-label"
            >{{i18n "academy_roles.student_invites.status"}}</div>{{i18n
              (concat "academy_roles.student_groups.states." item.status)
            }}</td>
          <td class="d-table__cell --detail"><div
              class="d-table__mobile-label"
            >{{i18n "academy_roles.student_groups.reason"}}</div>{{item.reason}}
            {{#each item.completed_add_groups as |name|}}<div>{{i18n
                  "academy_roles.student_groups.completed_add"
                  name=name
                }}</div>{{/each}}
            {{#each item.completed_remove_groups as |name|}}<div>{{i18n
                  "academy_roles.student_groups.completed_remove"
                  name=name
                }}</div>{{/each}}</td>
        </tr>
      {{else}}<tr class="d-table__row"><td
            class="d-table__cell"
            colspan="8"
          >{{i18n "academy_roles.student_groups.empty"}}</td></tr>{{/each}}
    </tbody>
  </table>
</template>
