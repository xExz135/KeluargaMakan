/**
 * Test helpers: a typed view of openapi.yaml. Not exported from the package.
 */
import { readFileSync } from "node:fs";

import { parse } from "yaml";

export interface SchemaObject {
  readonly type?: string | readonly string[];
  readonly enum?: readonly string[];
  readonly properties?: Readonly<Record<string, SchemaObject>>;
  readonly required?: readonly string[];
  readonly items?: SchemaObject;
  readonly oneOf?: readonly SchemaObject[];
  readonly allOf?: readonly SchemaObject[];
  readonly $ref?: string;
  readonly minimum?: number;
  readonly description?: string;
  readonly "x-data-sensitivity"?: string;
}

export interface MediaType {
  readonly schema?: SchemaObject;
}

export interface ResponseObject {
  readonly $ref?: string;
  readonly description?: string;
  readonly content?: Readonly<Record<string, MediaType>>;
}

export interface ParameterObject {
  readonly $ref?: string;
  readonly name?: string;
  readonly in?: string;
}

export interface OperationObject {
  readonly operationId?: string;
  readonly summary?: string;
  readonly description?: string;
  readonly tags?: readonly string[];
  readonly security?: readonly unknown[];
  readonly parameters?: readonly ParameterObject[];
  readonly requestBody?: { readonly content?: Readonly<Record<string, MediaType>> };
  readonly responses: Readonly<Record<string, ResponseObject>>;
  readonly "x-requirements"?: readonly string[];
}

export interface OpenApiDocument {
  readonly openapi: string;
  readonly info: { readonly version: string; readonly description?: string };
  readonly security?: readonly unknown[];
  readonly tags: readonly { readonly name: string }[];
  readonly paths: Readonly<Record<string, Readonly<Record<string, unknown>>>>;
  readonly components: {
    readonly schemas: Readonly<Record<string, SchemaObject>>;
    readonly responses: Readonly<Record<string, ResponseObject>>;
    readonly parameters: Readonly<Record<string, ParameterObject>>;
  };
}

export const HTTP_METHODS = ["get", "put", "post", "patch", "delete"] as const;
export type HttpMethod = (typeof HTTP_METHODS)[number];

export interface OperationEntry {
  readonly path: string;
  readonly method: HttpMethod;
  readonly operation: OperationObject;
}

export const SPEC_TEXT = readFileSync(new URL("../../openapi.yaml", import.meta.url), "utf8");
export const SPEC = parse(SPEC_TEXT) as OpenApiDocument;

export function operations(doc: OpenApiDocument = SPEC): OperationEntry[] {
  return Object.entries(doc.paths).flatMap(([path, item]) =>
    HTTP_METHODS.filter((method) => method in item).map((method) => ({
      path,
      method,
      operation: item[method] as OperationObject,
    })),
  );
}

export function operation(operationId: string): OperationEntry {
  const found = operations().find((entry) => entry.operation.operationId === operationId);
  if (!found) throw new Error(`operation ${operationId} not in openapi.yaml`);
  return found;
}

export function schema(name: string): SchemaObject {
  const found = SPEC.components.schemas[name];
  if (!found) throw new Error(`schema ${name} not in openapi.yaml`);
  return found;
}

export function refName(ref: string): string {
  const name = ref.split("/").pop();
  if (!name) throw new Error(`bad $ref ${ref}`);
  return name;
}

/** Names of component schemas referenced directly from `node`, at any depth inside it. */
export function directRefs(node: SchemaObject): string[] {
  const refs: string[] = [];
  const visit = (value: unknown): void => {
    if (Array.isArray(value)) {
      value.forEach(visit);
    } else if (value && typeof value === "object") {
      for (const [key, child] of Object.entries(value)) {
        if (key === "$ref" && typeof child === "string") refs.push(refName(child));
        else visit(child);
      }
    }
  };
  visit(node);
  return refs;
}

/** Every property name declared anywhere in the component schemas. */
export function allPropertyNames(): string[] {
  return Object.values(SPEC.components.schemas).flatMap((s) => Object.keys(s.properties ?? {}));
}

/** The enum of a property, following a direct or nullable `$ref`. */
export function propertyEnum(schemaName: string, property: string): readonly string[] {
  const prop = schema(schemaName).properties?.[property];
  if (!prop) throw new Error(`${schemaName}.${property} not found`);
  const target = prop.$ref ?? prop.oneOf?.find((s) => s.$ref)?.$ref ?? prop.allOf?.[0]?.$ref;
  const values = target ? schema(refName(target)).enum : prop.enum;
  if (!values) throw new Error(`${schemaName}.${property} has no enum`);
  return values;
}
