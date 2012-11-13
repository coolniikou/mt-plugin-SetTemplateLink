package SetTemplateLink::Plugin;

use strict;
use MT;
use Data::Dumper;

sub can_use_set {
    my $app = MT->app;
    return $app->user->is_superuser;
}

sub hdlr_set_linkedfile_templates {
    my $app = shift;
    return $app->permission_denied() unless $app->user->is_superuser;

    my $blog    = $app->blog;
    my $blog_id = $blog->id;
    my $plugin  = MT->component('SetTemplateLink');
    my $path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );
    return $app->error(
        $app->translate(
            "Should be set the linked path in the plugin setting.: [_1]",
            $plugin->errstr
        )
    ) if !$path;

    my $fmgr = $blog->file_mgr;
    unless ( $fmgr->exists($path) ) {
        $fmgr->mkpath($path);
    }

    if ( $fmgr->exists($path) && $fmgr->can_write($path) ) {
        require MT::Template;
        my $temp_iter = MT::Template->load_iter( { blog_id => $blog->id } );
        while ( my $temp = $temp_iter->() ) {
            next if( $temp->name =~ /Backup/g);
            my $template_id = $temp->id;
            my $template_name = $temp->name;
            my $basename;
            if(!$temp->identifier && $temp->name !~ /[^\x01-\x7E]|Backup/) {
                $basename = lc($temp->name). '.mtml';
                $temp->identifier( lc($temp->name) );
            }
            else {
                $basename    = $temp->identifier . '.mtml';
            }

            my $linked_path = File::Spec->catfile( $path, $basename );
            $temp->linked_file($linked_path);
            $temp->save
              or die $app->error(
                $plugin->translate(
                    "Can not save template linked_file.: [_1]",
                    $temp->errstr
                )
              );
            $app->log( { 
                message => $app->translate(
                "Success template  set name:[_1], ID :#[_2], type :[_3], Identifier :[_4], LinkedFilePath: [_5]",
                $temp->name, $temp->id, $temp->type,
                $temp->identifier, $temp->linked_file),
            } );

        }
        $app->call_return;
    }
    else {
        return $app->error(
            $app->translate(
                "Unable to create file in this path: [_1]", $path
            )
        );
    }

}

1;
