import DSelect from "discourse/ui-kit/d-select";

declare const multiple: boolean;
declare function singleChanged(value: string | null): void;
declare function multipleChanged(value: string[]): void;
declare function dynamicChanged(value: string | string[] | null): void;
declare function inputChanged(event: Event): void;

const Test = <template>
  <DSelect
    name="campus"
    @onChange={{singleChanged}}
    @onInput={{inputChanged}}
    @required={{true}}
    @value={{false}}
    as |select|
  >
    <select.Option @value={{false}}>False</select.Option>
    <select.Option @value={{0}}>Zero</select.Option>
  </DSelect>
  <DSelect @multiple={{true}} @onChange={{multipleChanged}} as |select|>
    <select.Option @value="a">Alpha</select.Option>
    <optgroup label="More"><option value="b">Beta</option></optgroup>
  </DSelect>
  <DSelect @multiple={{multiple}} @onChange={{dynamicChanged}} />
</template>;

export default Test;
