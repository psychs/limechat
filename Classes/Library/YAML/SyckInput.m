#import "YAML.h"
#import <syck.h>
#import "GTMBase64.h"

void cocoa_syck_error_handler( SyckParser *p, const char *msg )
{
	NSLog(@"syck error:%s position:(%d, %lu)", msg, p->linect, p->cursor - p->lineptr);
}

SYMID cocoa_syck_parse_handler(SyckParser *p, SyckNode *n)
{
    SYMID oid;
    id o2, o3;
    id v = NULL;
    long i = 0;
    char *type_id = n->type_id;
    int transferred = 0;
	
	if ( type_id != NULL && strncmp( type_id, "tag:yaml.org,2002:", 18 ) == 0 )
    {
        type_id += 18;
    }
	
    switch ( n->kind )
    {
        case syck_str_kind:
            transferred = 1;
			if ( type_id == NULL || strcmp( type_id, "str" ) == 0 )
            {
				v = [NSString yamlStringWithUTF8String:n->data.str->ptr length:n->data.str->len];
            }
            else if ( strcmp( type_id, "null" ) == 0 )
			{
				v = [NSNull null];
			}
            else if ( strcmp( type_id, "binary" ) == 0 )
			{
				v = [GTMBase64 decodeString:[NSString yamlStringWithUTF8String:n->data.str->ptr length:n->data.str->len]];
            
                NSString *string = [NSString yamlStringWithUTF8String:[v bytes] length:[v length]];
                if(string) 
                {
                    v = string;
                }
            }
			else if ( strcmp( type_id, "bool#yes" ) == 0 )
			{
				v = [NSNumber numberWithBool:YES];
			}
            else if ( strcmp( type_id, "bool#no" ) == 0 )
			{
				v = [NSNumber numberWithBool:NO];
			}
            else if ( strcmp( type_id, "int#hex" ) == 0 )
            {
                syck_str_blow_away_commas( n );
                long i2 = strtol( n->data.str->ptr, NULL, 16 );
				v = [NSNumber numberWithLong:i2];
            }
            else if ( strcmp( type_id, "int#oct" ) == 0 )
            {
                syck_str_blow_away_commas( n );
                long i2 = strtol( n->data.str->ptr, NULL, 8 );
				v = [NSNumber numberWithLong:i2];
            }
            else if ( strcmp( type_id, "int#base60" ) == 0 )
            {
                char *ptr, *end;
                long sixty = 1;
                long total = 0;
                syck_str_blow_away_commas( n );
                ptr = n->data.str->ptr;
                end = n->data.str->ptr + n->data.str->len;
                while ( end > ptr )
                {
                    long bnum = 0;
                    char *colon = end - 1;
                    while ( colon >= ptr && *colon != ':' )
                    {
                        colon--;
                    }
                    if ( *colon == ':' ) *colon = '\0';

                    bnum = strtol( colon + 1, NULL, 10 );
                    total += bnum * sixty;
                    sixty *= 60;
                    end = colon;
                }
                v = [NSNumber numberWithLong:total];
            }
            else if ( strncmp( type_id, "int", 3 ) == 0 )
            {
                syck_str_blow_away_commas( n );
				v = [NSNumber numberWithLong:strtol( n->data.str->ptr, NULL, 10 )];
            }
            else if ( strcmp( type_id, "float#base60" ) == 0 )
            {
                char *ptr, *end;
                long sixty = 1;
                double total = 0.0;
                syck_str_blow_away_commas( n );
                ptr = n->data.str->ptr;
                end = n->data.str->ptr + n->data.str->len;
                while ( end > ptr )
                {
                    double bnum = 0;
                    char *colon = end - 1;
                    while ( colon >= ptr && *colon != ':' )
                    {
                        colon--;
                    }
                    if ( *colon == ':' ) *colon = '\0';

                    bnum = strtod( colon + 1, NULL );
                    total += bnum * sixty;
                    sixty *= 60;
                    end = colon;
                }
                v = [NSNumber numberWithFloat:total];
            }
            else if ( strcmp( type_id, "float#nan" ) == 0 )
            {
				v = [NSNumber numberWithFloat:NAN];
            }
            else if ( strcmp( type_id, "float#inf" ) == 0 )
            {
				v = [NSNumber numberWithFloat:INFINITY];
            }
            else if ( strcmp( type_id, "float#neginf" ) == 0 )
            {
				v = [NSNumber numberWithFloat:-INFINITY];
            }
            else if ( strncmp( type_id, "float", 5 ) == 0 )
            {
                syck_str_blow_away_commas( n );
				v = [NSNumber numberWithFloat:strtod( n->data.str->ptr, NULL )];
            }
/*
			else if ( strcmp( type_id, "timestamp#iso8601" ) == 0 )
            {
                v = [NSDate dateWithNaturalLanguageString:[NSString stringWithUTF8String:n->data.str->ptr length:n->data.str->len]];
            }
            else if ( strcmp( type_id, "timestamp#spaced" ) == 0 )
            {
                v = [NSDate dateWithNaturalLanguageString:[NSString stringWithUTF8String:n->data.str->ptr length:n->data.str->len]];
            }
            else if ( strcmp( type_id, "timestamp#ymd" ) == 0 )
            {
                v = [NSDate dateWithNaturalLanguageString:[NSString stringWithUTF8String:n->data.str->ptr length:n->data.str->len]];
            }
 */
/*
#if !TARGET_OS_IPHONE
            else if ( strncmp( type_id, "timestamp", 9 ) == 0 )
            {
                v = [NSDate dateWithNaturalLanguageString:[NSString stringWithUTF8String:n->data.str->ptr length:n->data.str->len]];
            }
#endif
*/
            else if ( strncmp( type_id, "merge", 5 ) == 0 )
            {
                v = @"MERGE"; //rely on constants being the same
            }
            else
            {
				v = [NSString yamlStringWithUTF8String:n->data.str->ptr length:n->data.str->len];
				transferred = 0;
            }
        break;

        case syck_seq_kind:
			v = [NSMutableArray array];
            for ( i = 0; i < n->data.list->idx; i++ )
            {
                oid = syck_seq_read( n, i );
                syck_lookup_sym( p, oid, (char **)&o2 );
				[v addObject:o2];
            }
            if ( type_id != NULL && strcmp( type_id, "set" ) == 0 )
            {
				v = [NSSet setWithArray:v];
                transferred = 1;
            }
            else if ( type_id == NULL || strcmp( type_id, "seq" ) == 0 )
            {
                transferred = 1;
            }
        break;

        case syck_map_kind:
            v = [NSMutableDictionary dictionary];
            for ( i = 0; i < n->data.pairs->idx; i++ )
            {
                oid = syck_map_read( n, map_key, i );
                syck_lookup_sym( p, oid, (char **)&o2 );
                oid = syck_map_read( n, map_value, i );
                syck_lookup_sym( p, oid, (char **)&o3 );
				
				if(o2 == @"MERGE")
				{
					if([o3 isKindOfClass:[NSDictionary class]])
						[v addEntriesFromDictionary:o3];
					else if([o3 isKindOfClass:[NSArray class]])
						[v yamlPerformSelector:@selector(addEntriesFromDictionary:) withEachObjectInArray:o3];
				}
				else
					[v setObject:o3 forKey:o2];
            }
            if ( type_id == NULL || strcmp( type_id, "map" ) == 0 )
            {
                transferred = 1;
            }
        break;
    }
	
	// types
	if(!transferred && type_id != NULL)
	{
		NSString *type = [NSString stringWithUTF8String:type_id];
		if([type hasPrefix:@"x-private:"])
		{
			//Class	myClass = NSClassFromString([type substringFromIndex:10]);
			//if(myClass) v = [myClass objectWithYAML:v];
		}
	}
	
	//make sure any bad creations don't kill whole parse
	if(!v)
		v = [NSNull null];

    oid = syck_add_sym( p, (char*)v );
    return oid;
}

id yaml_parse_raw_utf8(const char *str, long len) 
{
    id obj = NULL;
    SYMID v;
    SyckParser *parser = syck_new_parser();
    
    syck_parser_str( parser, str, len, NULL );
    syck_parser_handler( parser, cocoa_syck_parse_handler );
    syck_parser_error_handler( parser, cocoa_syck_error_handler);
    syck_parser_implicit_typing( parser, 1 );
    syck_parser_taguri_expansion( parser, 1 );
    
    v = syck_parse( parser );
    if(v)
        syck_lookup_sym( parser, v, (char **)&obj );
	
    syck_free_parser( parser );
    return obj;    
}

id yaml_parse(NSString *str)
{
    const char *yamlstr = [str UTF8String];
    return yaml_parse_raw_utf8(yamlstr, strlen(yamlstr));
}