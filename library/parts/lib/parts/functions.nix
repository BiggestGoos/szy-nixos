{ lib, ... }:
{

	content =
	rec {

		# Whether or not a given value is a function or functor
		# isCallable :: Any -> Bool
		isCallable = value: (builtins.isFunction value) || ((builtins.isAttrs value) && (value ? __functor));

		# Resolve a value, either it is a function to value or just value.
		# resolveValue :: Any -> Any -> Any
		resolveValue = value: argument: (lib.trivial.toFunction value) argument;

		/*
			Resolve a set of inputs to follow a schema.

			The schema consists of three "types":
			- Defaulted values: [ value ]. A value wrapped in a list.
			- Nested values: { name = <schema type>; }. A set of nested values with any type.
			- Required values: Values that are neither defaulted nor nested.

			Cases:
			- If the schema defines 'x' as nested and 'x' is not supplied then 
			checking of requiredness should be deferred to the nested evaluation.
			- If the schema defines 'x' as nested and 'x' is an empty set then
			that should be seen as no input and should lead to the nested defaults 
			or errors.
		*/
		# followSchema :: AttrSet -> AttrSet -> AttrSet
		followSchema = schema': inputs:
		let
			
			schema = resolveValue schema' final;

			suppliedNotInSchema = builtins.any (x: x == false)
			(
				lib.attrsets.mapAttrsToList
				(
					name: _:
					if builtins.hasAttr name schema
					then true
					else builtins.throw "Supplied value \"${name}\" is not in the schema!"
				) inputs
			);

			final =
			if suppliedNotInSchema
			then {}
			else
			lib.attrsets.mapAttrs
			(
				name: value':
				let
					isDefaulted = builtins.isList value';
					isNested = value' != {} && builtins.isAttrs value';

					isSupplied = builtins.hasAttr name inputs;
					suppliedValue = inputs."${name}";
					suppliedConforms =
					if isNested 
					then builtins.isAttrs suppliedValue
					else true;

					value =
					if !isSupplied
					then 
					(
						if isNested
						then followSchema value' {}
						else
						(
							if isDefaulted # Not being defaulted equates to being required
							then builtins.head value'
							else builtins.throw "Required value \"${name}\" is not supplied!"
						)
					)
					else
					(
						if suppliedConforms
						then
						(
							if isNested
							then followSchema value' suppliedValue
							else suppliedValue
						)
						else builtins.throw "Supplied value for \"${name}\" does not follow schema!"
					);
				in
					value
			) schema;

		in
			final;

	};

}
